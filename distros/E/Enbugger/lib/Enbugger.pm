package Enbugger;

# COPYRIGHT AND LICENCE
#
# Copyright (C) 2007,2008,2009 WhitePages.com, Inc. with primary
# development by Joshua ben Jore.
#
# This program is distributed WITHOUT ANY WARRANTY, including but not
# limited to the implied warranties of merchantability or fitness for
# a particular purpose.
#
# The program is free software.  You may distribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (either version 2 or any later version)
# and the Perl Artistic License as published by O’Reilly Media, Inc.
# Please open the files named gpl-2.0.txt and Artistic for a copy of
# these licenses.

BEGIN {
    $VERSION = '2.016';
}

use XSLoader ();

BEGIN {
    XSLoader::load( 'Enbugger', $VERSION );


    # Provide minimal debugger hooks.
    #
    # When perl has debugging enabled, it always calls these functions
    # at hook points. It dies if they're missing. These stub functions
    # don't do anything except provide something that will keep perl
    # from dying from lack of hooks.
    {

        # Generate needed code for stubs.
        my $src = "package DB;\n";
        my $need_stubs;
        for my $sub (qw( DB sub )) {
            my $globref = $DB::{$sub};

            # Don't try replacing an existing function.
            if ( $globref and defined &$globref ) {
            }
            else {
                # Generate a stub method.
                $src .= "sub $sub {};\n";
                $need_stubs = 1;
            }
        }

        # Create stubs.
        if ( $need_stubs ) {
            $src .= "return 1;\n";
            my $ok = eval $src;
            die $@ unless $ok;
        }
    }


    # Compile and load everything following w/ debugger hooks.
    #
    # That is, everything I'm asking to compile now could possibly be
    # debugged if we do the loading. Most of everything else in the
    # Enbugger namespace is explicitly removed from the debugger by
    # making sure it's COP nodes are compiled with "nextstate" instead
    # of "dbstate" hooks.
    Enbugger->_compile_with_dbstate();
}


# I don't know the real minimum version. I've gotten failure
# reports from 5.5 that show it's missing the COP opcodes I'm
# altering.
use 5.006_000;

use strict;

use B::Utils ();
use Carp ();
use Scalar::Util ();

# Public class settings.
use vars qw( $DefaultDebugger %DBsub );

use constant (); # just to load it.

BEGIN {
    # Compile all of Enbugger:: w/o debugger hooks.
    Enbugger->_compile_with_nextstate();
}

our( $DEBUGGER, $DEBUGGER_CLASS, %REGISTERED_DEBUGGERS );




######################################################################
# Public API

BEGIN {
    my $src = "no warnings 'redefine';\n";
    for my $sub (qw( stop write )) {
        $src .= <<"SRC";
#line @{[__LINE__+1]} "@{[__FILE__]}"
            sub $sub {
                my ( \$class ) = \@_;

                # Fetch and install the real implementation.
                my \$debuggerSubClass = \$class->DEBUGGER_CLASS;

                *Enbugger::$sub = \$debuggerSubClass->can('_${sub}');

                # Redispatch to the implementation.
                goto &Enbugger::$sub;
            };
SRC
    }

    $src .= "return 1;\n";
    my $ok = eval $src;
    die $@ unless $ok;
}





BEGIN { $DefaultDebugger = 'perl5db' }

sub DEBUGGER_CLASS () {
    unless ( defined $DEBUGGER_CLASS ) {
        Enbugger->load_debugger;
    }

    # Install a replacement method that doesn't know how to load
    # debuggers.
    #
    # There's no need to always have a 100% capable function around
    # once there's no possibility for change.
    my $ok = eval <<"DEBUGGER_CLASS";
#line @{[__LINE__]} "@{[__FILE__]}"
        no warnings 'redefine';
        sub DEBUGGER_CLASS () {
            "\Q$DEBUGGER_CLASS\E"
        }
        return 1;
DEBUGGER_CLASS

    die $@ unless $ok;

    goto &Enbugger::DEBUGGER_CLASS;
}









sub _stop;
sub _write;
sub _load_debugger;






BEGIN {
    # There is an automatically registered "null" debugger which is
    # really just a known empty thing that exists only so I can match
    # against it and thereby know it can be replaced.
    $REGISTERED_DEBUGGERS{''} = {
                                null    => 1,
                                symbols => [qw[ sub DB ]],
                               };
}

sub load_debugger {
    my ( $class, $requested_debugger ) = @_;

    # Choose a debugger to load if none was specified.
    if ( not defined $requested_debugger ) {

        # Don't bother if we've already loaded a debugger.
        return if $DEBUGGER;

        # Choose the default.
        $requested_debugger = $DefaultDebugger;
    }

    # Don't load a debugger if there is one loaded already.
    #
    # Enbugger already populates %DB:: with &DB and &sub so I'll check
    # for something that I didn't create.
    my %debugger_symbols =
      map {; $_ => 0b01 }
        keys %DB::;


    # Compare all registered debuggers to our process.
    my %debugger_matches;
    for my $debugger ( keys %REGISTERED_DEBUGGERS ) {
        
        # Find the intersection vs the difference.
        my $intersection = 0;
        my %match = %debugger_symbols;
        for my $symbol ( @{$REGISTERED_DEBUGGERS{$debugger}{symbols}} ) {
            if ( ( $match{$symbol} |= 0b10 ) == 0b11 ) {
                ++ $intersection;
            }
        }
        
        # Score.
        my $difference =
          keys(%match) - $intersection;
        my $score = $difference / $intersection;
        
        $debugger_matches{$debugger} = $score;
    }

    # Select the best matching debugger.
    my ( $best_debugger ) =
      sort { $debugger_matches{$a} <=> $debugger_matches{$b} }
        keys %debugger_matches;
    
    
    # It is ok to replace the null debugger but an error to replace
    # anything else. Also, there's nothing to do if we've already
    # loaded the requested debugger.
    if ( $REGISTERED_DEBUGGERS{$best_debugger}{null} ) {
    }
    elsif ( $best_debugger eq $requested_debugger ) {
        return;
    }
    else {
        Carp::confess("Can't replace the existing $best_debugger debugger with $requested_debugger");
    }


    # Debugger's name -> Debugger's class.
    $DEBUGGER = $requested_debugger;
    $DEBUGGER_CLASS = "${class}::$DEBUGGER";

    # Debugger's class -> Debugger's .pm file.
    my $debugger_class_file = $DEBUGGER_CLASS;
    $debugger_class_file =~ s#::#/#g;
    $debugger_class_file .= '.pm';

    # Load the file.
    #
    # Be darn sure we're compiling COP nodes with pp_nextstate
    # instead of pp_dbstate. It sucks to start debugging your
    # debugger by accident. Incidentally... this is a great place
    # to hack if you /do/ want to make debugging a debugger a
    # possibility.
    #
    # Further, note that some debugger supports have already been loaded 
    # by __PACKAGE__->register_debugger(...) below. In general, this
    # is for things I've needed to use myself.
    Enbugger->_compile_with_nextstate();
    require $debugger_class_file;
    $DEBUGGER_CLASS->_load_debugger;
    $DEBUGGER_CLASS->instrument_runtime;


    # Subsequent compilation will use pp_dbstate like expected.
    $DEBUGGER_CLASS->_instrumented_ppaddr();

    return;
}



sub _uninstrumented_ppaddr { $_[0]->_compile_with_nextstate() }
sub _instrumented_ppaddr   { $_[0]->_compile_with_dbstate()   }






sub _load_debugger;





sub register_debugger {
    my ( $class, $debugger ) = @_;
    
    # name -> class
    my $enbugger_subclass = "Enbugger::$debugger";

    # class -> module file
    my $enbugger_subclass_file = $enbugger_subclass;
    $enbugger_subclass_file =~ s<::></>g;
    $enbugger_subclass_file .= '.pm';

    # Load it. *Assume* PL_ppaddr[OP_NEXTSTATE] is something
    # useful like Perl_pp_nextstate still.
    #
    # TODO: localize PL_ppaddr[OP_NEXTSTATE] during this compilation to 
    # be Perl_pp_nextstate.
    require $enbugger_subclass_file;


    my $src = <<"REGISTER_DEBUGGER";
#line @{[__LINE__]} "@{[__FILE__]}"
        sub load_$debugger {
            my ( \$class ) = \@_;
            \$class->load_debugger( '$debugger' );
            return;
        };
REGISTER_DEBUGGER

    $src .= "return 1;\n";
    my $ok = eval $src;
    die $@ unless $ok;
}





sub load_source {
    my ( $class ) = @_;

    # Load the original program.
    $class->load_file($0);

    # Load all modules.
    for ( grep { defined and -e } values %INC ) {
        $class->load_file($_);
    }

    $class->initialize_dbline;

    return;
}


sub initialize_dbline {
     my $file;
     for ( my $cx = 1; my ( $package, $c_file ) = caller $cx; ++ $cx ) {
         if ( $package !~ /^Enbugger/ ) {
             $file = $c_file;
             last;
         }
     }

     if ( not defined $file ) {
         *DB::dbline = [];
         *DB::dbline = {};
         Enbugger::set_magic_dbfile( \%DB::dbline );
     }
     else {
         no strict 'refs';
         *DB::dbline = \*{"main::_<$file"};
     }
}




sub load_file {
    my ($class, $file) = @_;
    
    # The symbols by which we'll know ye.
    my $base_symname = "_<$file";
    my $symname          = "main::$base_symname";
    
    no strict 'refs';

    my $glob = \*$symname;

    if ( ! *$symname{ARRAY} && -f $file ) {
        # Read the source.
        # Open the file.
        my $fh;
        if ( not open $fh, '<', $file ) {
            Carp::croak( "Can't open $file for reading: $!" );
        }
        
        # Load our source code. All source must be installed as at least PVIV or
        # some asserts in op.c may fail. Later, I'll assign better pointers to each
        # line in instrument_op.
        local $/ = "\n";
        *$glob = [
            map { Scalar::Util::dualvar( 0, $_ ) }
            ( "BEGIN { require 'perl5db.pl' } # Generated by " . __FILE__,
	      readline $fh )
        ];
    }

    if ( ! *$glob{HASH} ) {
        my %breakpoints;
        Enbugger::set_magic_dbfile(\%breakpoints);
        *$glob = \%breakpoints;
    }
    
    $$symname ||= $file;
    
    return;
}







sub instrument_runtime {
    # Now do the *real* work.
    my ( $class ) = @_;

    # PL_DBgv = gv_fetchpvs("DB::DB", GV_ADDMULTI, SVt_PVGV);
    eval 'sub DB::DB {}' if ! defined &DB::DB;

    # Load the source code for all loaded files. Too bad about (eval 1)
    # though. This doesn't work. Why not!?!
    $class->load_source;

    # PL_DBsingle = GvSV((gv_fetchpvs("DB::single", GV_ADDMULTI, SVt_PV)));
    # if (!SvIOK(PL_DBsingle))
    #     sv_setiv(PL_DBsingle, 0);
    $DB::single = 0 if ! defined $DB::single;

    # PL_DBtrace = GvSV((gv_fetchpvs("DB::trace", GV_ADDMULTI, SVt_PV)));
    # if (!SvIOK(PL_DBtrace))
    #     sv_setiv(PL_DBtrace, 0);
    $DB::trace = 0 if ! defined $DB::trace;

    # PL_DBsignal = GvSV((gv_fetchpvs("DB::signal", GV_ADDMULTI, SVt_PV)));
    # if (!SvIOK(PL_DBsignal))
    #     sv_setiv(PL_DBsignal, 0);
    $DB::signal = 0 if ! defined $DB::signal;

    # Walk over all optrees.
    # * Transform nextstate COP* nodes to dbstate COP* nodes as appropriate
    # * Set ${"main::_<$file"}[X] array elements with COP* pointers
    # * Capture function name start/end line numbers
    B::Utils::walkallops_simple( \ &Enbugger::instrument_op );

    # Provide %DB::sub.
    %DB::sub =
        map { $_ => sprintf '%s:%d-%d', @{$DBsub{$_}} }
        keys %DBsub;
    undef %DBsub;
}





sub instrument_op {
    my ( $op ) = @_;

    # Must be a B::COP node.
    if ( $$op and B::class( $op ) eq 'COP' ) {

        # @{"_<$file"} entries where there are COP entries are
        # dualvars of pointers to the COP nodes that will get
        # OPf_SPECIAL toggled to indicate breakpoints.
	my $ptr  = $$op;
	my $source = do {
	    no strict 'refs';
	    \ @{"main::_<$B::Utils::file"};
	};
	if ( $ptr ) {
	    $source->[$B::Utils::line] = Scalar::Util::dualvar( $ptr, $source->[$B::Utils::line] );
	}

	if ($DBsub{$B::Utils::sub}) {
	    $DBsub{$B::Utils::sub}[1] = $B::Utils::line if $B::Utils::line < $DBsub{$B::Utils::sub}[1];
	    $DBsub{$B::Utils::sub}[2] = $B::Utils::line if $B::Utils::line > $DBsub{$B::Utils::sub}[2];
	}
	else {
	    $DBsub{$B::Utils::sub} = [ $B::Utils::file, ($B::Utils::line) x 2 ];
	}

        #print $op->file ."\t".$op->line."\t".$o->stash->NAME."\t";
        # Disable or enable debugging for this opcode.
        if ( $op->stash->NAME =~ /^(?=[DE])(?:DB|Enbugger)(?:::|\z)/ ) {
            #print 'next';
            Enbugger::_nextstate_cop( $op );
        }
        else {
            Enbugger::_dbstate_cop( $op );
        }
    }
}





sub import {
    my $class = shift @_;

    if ( @_ ) {
        my $selected_debugger = shift @_;
        $DefaultDebugger = $selected_debugger;
    }
}


BEGIN {
    __PACKAGE__->register_debugger( 'perl5db' );
    __PACKAGE__->register_debugger( 'trepan' );
    __PACKAGE__->register_debugger( 'NYTProf' );
}
# TODO: __PACKAGE__->register_debugger( 'ebug' );
# TODO: __PACKAGE__->register_debugger( 'sdb' );
# TODO: __PACKAGE__->register_debugger( 'ptkdb' );


# Anything compiled after this statement runs will be debuggable.
Enbugger->_compile_with_dbstate();

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## tab-width: 8
## End:

no warnings 'void'; ## no critic
'But this is the internet, dear, stupid is one of our prime exports.';
