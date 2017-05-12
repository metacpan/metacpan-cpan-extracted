#! /usr/bin/perl

#===============================================================================
#
#         FILE:  Auto.pm
#
#        USAGE:  use Getopt::Auto
#
#  DESCRIPTION:  Processes the command line when your Perl script is executed,
#                looking for the options you define in your POD.
#
#      OPTIONS:  --- None
# REQUIREMENTS:  --- See Build.PL
#         BUGS:  --- Hah!
#       AUTHOR:  Geoffrey Leach (), geoff@hughes.net
#      VERSION:  2.0
#     REVISION:  ---
#===============================================================================

#  Copyright (C) 2003-2009, Simon Cozens
#  Copyright (C) 2010-2011, Geoffrey Leach

package Getopt::Auto;

use 5.006;
use strict;
use warnings;

use Carp;

use File::Basename;
use File::Spec;
use Readonly;

Readonly::Scalar my $SPACE   => q{ };
Readonly::Scalar my $EMPTY   => q{};
Readonly::Scalar my $DASH    => q{-};
Readonly::Scalar my $DDASH   => q{--};
Readonly::Scalar my $BARE    => 0;
Readonly::Scalar my $SHORT   => 1;
Readonly::Scalar my $LONG    => 2;
Readonly::Array my @TYPES    => qw( bare short long );
Readonly::Array my @PREFIXES => ( $EMPTY, $DASH, $DDASH );

our $VERSION = '2.0';

# Perlcritic complains about print to STDOUT. As this is merely for
# diagnostic purposes, it seems futile to fix them.

## no critic (RequireCheckedSyscalls)

# Initialized by import(), used throughout
# Successive calls to import add to it, allowing code to work off
# of a particular script or module
# Each element is a list of
# 0: [package, file], as returned by caller() in import()
# 1: The package's options hash (our %options), or main::options
# 2: Hash of controls as given in call of Getopt::Auto
#    nobare, noshort, nolong, trace, init, findsub
my @callers;

# $caller is the current value of @callers when iterating and is
# used by subroutines that do not have a way to get it via a parameter
our $caller;    ## no critic (ProhibitPackageVars)

# User-requested global behaviors
# 'test' is intentionally undocumented
# It is used to avoid exiting on errors for test purposes
my %config = (
    'trace'    => undef,
    'noshort'  => undef,
    'nolong'   => undef,
    'nobare'   => undef,
    'nohelp'   => undef,
    'nobundle' => undef,
    'oknotreg' => undef,
    'okerror'  => undef,
    'findsub'  => undef,
    'init'     => undef,
    'test'     => undef,
);

my $errors = 0;

# CHECK is a specially-named block, that is executed by Perl at the _completion_ of compillation.
# This is critical, because _parse_pod() depends (indirectly, see Getopt::Auto::PodExtract)
# on the existence of subroutines to process the options. It's only executed _once_, however
# many times "use Getopt::Auto" has appeared. We've accumulated those packages; now we'll
# process them.

CHECK {

    #$DB::single = 2;    ## no critic (ProhibitPackageVars)
    if ($errors) {
        if ( not defined $config{'test'} ) { exit 1; }
    }
    _parse_pod();
}

# INIT is a specially-named block that is executed immediatly preceding the
# start of the program.

INIT {

    #$DB::single = 2;    ## no critic (ProhibitPackageVars)
    _parse_args();
    if ($errors) {
        if (   ( not defined $config{'okerror'} )
            && ( not defined $config{'test'} ) )
        {
            exit 1;
        }
    }
}

# Executed when the Perl program is about to exit
# Retained for compabilility with V 1.0; I've no idea what it does

END {
    if ( exists &main::default ) { main::default() }
}

# Please note: subroutine names that begin with an underscore are internal.
# Calling sequence and/or existence is not guaranteed for future versions.

# $their_version is managed by Getopt::Auto::PodExtract::preprocess_line()
# _set_their_version() assigns and _get_their_version() reports.
# their_version is the value of $VERSION in the source POD.

my $their_version;

sub _set_their_version {
    $their_version = shift;
    return;
}

sub _get_their_version {
    return $their_version;
}

# Carries the content of Getopt::Auto(...)
our @spec;    ## no critic (ProhibitPackageVars)
Readonly::Scalar my $SPEC_NAME  => 0;
Readonly::Scalar my $SPEC_SHORT => 1;
Readonly::Scalar my $SPEC_LONG  => 2;
Readonly::Scalar my $SPEC_CODE  => 3;
Readonly::Scalar my $SPEC_SIZE  => 4;

sub _get_spec_ref {
    return \@spec;
}

# Allows user to say what style to prefer
# Values are 'short', 'long', 'bare', default 'long' or 'undef' meaning use the POD;
my $help_p = $LONG;

# %options contains the option registration data extracted from the POD
# (or from the use Getopt::Auto statement). It's loaded by _parse_pod()
# and used by _parse_args() when an option is discovered on the run-time command.

our %options;    ## no critic (ProhibitPackageVars)

# This sub is intended for testing only. Absence of leading '_' is only to
# satisfy perlcritic.
sub test_option {
    my $query = shift;
    return exists $options{$query} && !_is_restricted($query);
}

sub _get_options_ref {
    return \%options;
}

sub _trace {
    if ( not defined $config{'trace'} ) {
        return;
    }
    my $arg = shift;
    chomp $arg;
    print "Getopt::Auto trace: $arg\n";
    return;
}

sub _trace_spec {
    if ( not defined $config{'trace'} ) {
        return;
    }
    my $spec = shift;
    print "Getopt::Auto trace: Spec for $spec->[$SPEC_NAME]: ";
    print length $spec->[$SPEC_SHORT]
        ? "$spec->[$SPEC_SHORT], "
        : "no short help, ";
    print defined $spec->[$SPEC_LONG]
        ? "$spec->[$SPEC_LONG], "
        : "no long help, ";
    print defined $spec->[$SPEC_CODE]
        ? "$spec->[$SPEC_CODE]"
        : "no code";
    print "\n";
    return;
}

sub _trace_argv {
    if ( not defined $config{'trace'} ) {
        return;
    }
    _trace( 'Getopt::Auto trace: ARGV now: (' . join( ', ', @ARGV ) . ')' );
    return;
}

sub get_errors {
    return $errors;
}

sub _error {
    my $msg = shift;
    print {*STDERR} 'Getopt::Auto: ', $msg, "\n";
    $errors++;
    return;
}

# Modifies $name to make it an acceptable subrotine name.

sub _clean_func {
    my $func = shift;
    $func =~ s{\A-+}{}smx;
    $func =~ s{-}{_}smgx;
    return $func;
}

# Checks $pkg to see if there's a subroutine $name.
# $name will be an option, that is for --foo we look to 
# see if there's a sub foo() Return it if so.

sub _check_func {
    my ( $name, $pkg ) = @_;
    if ( not defined $caller ) {
        return;
    }
    if ( not defined $pkg ) {
        $pkg = qq{$caller->[0][0]::};
    }

    my $func = _clean_func($name);
    if ( exists &{"$pkg$func"} ) {
        _trace("For $name code is $func()");
        _trace("$pkg$func exists");
        no strict 'refs';    ## no critic (ProhibitNoStrict)
        return *{"$pkg$func"}{'CODE'};
    }
    else {
        _trace("There is no $pkg$func");
        return;
    }
    return;
}

# Look in all packages for a sub $name. If so, return it
# and store it in %options for future use. Note that
# at the point where this sub is called, we've determined
# that the option is not 'registered' and we wish to avoid
# registering the option by accident
# An nregistered option is something like --foo, where --foo
# did not appear in a =head line in the POD.

sub _check_all_sub {
    my $name = shift;
    _trace("Checking for sub $name");

    if (    ( exists $options{$name} )
        and ( exists $options{$name}{'code'} ) )
    {
        return $options{$name}{'code'};
    }

    # Check in all packages
    foreach my $caller_local (@callers) {
        my $sub = _check_func( $name, qq{$caller_local->[0][0]::} );
        if ( defined $sub ) {
            $options{$name}{'code'} = $sub;
            return $sub;
        }
    }
    return;
}

sub _is_restricted {
    my $arg      = shift;
    my $arg_type = _option_type($arg);
    if (( ( $arg_type == $BARE ) && ( defined $config{'nobare'} ) )
        || (   ( $arg_type == $SHORT )
            && ( defined $config{'noshort'} ) )
        || (   ( $arg_type == $LONG )
            && ( defined $config{'nolong'} ) )
        )
    {
        return 1;
    }
    return 0;
}

# The specs parameter is assumed to be a ref to a 4-element array
# The elementts are options found either in the POD or the use Getopt::Auto

sub _load_options {
    my ( $specs, $caller_local ) = @_;
    foreach my $spec ( @{$specs} ) {
        my $name = $spec->[$SPEC_NAME];

        $options{$name}{'shorthelp'}  = $spec->[$SPEC_SHORT];
        $options{$name}{'longhelp'}   = $spec->[$SPEC_LONG];
        $options{$name}{'package'}    = $caller_local->[0][0];
        $options{$name}{'options'}    = $caller_local->[1];
        $options{$name}{'registered'} = 1;

        # Avoid creating a code reference that's undefined
        if ( defined $spec->[$SPEC_CODE] ) {
            $options{$name}{'code'} = $spec->[$SPEC_CODE];
        }
        _trace_spec($spec);
    }
    return;
}

# Check a spec that's been given us by the user.

sub _check_spec {
    my ( $spec_ref, $caller_local ) = @_;

    foreach my $spec ( @{$spec_ref} ) {

        # Each spec has the following members:
        #   The option name: we need to check it for consistency.
        #   The short help phrase, from the POD =item or =head
        #   The long help message, from the POD paragraph that follows
        #   The code (sub reference) to be called for the option

        if ( not( ref $spec eq 'ARRAY' ) ) {
            _error(qq{Option specification $spec must be a reference});
            return;
        }

        if ( @{$spec} != $SPEC_SIZE ) {
            _error(qq{Option list is incompletly specified});
            return;
        }

        push @spec, $spec;
    }

    _load_options( \@spec, $caller_local );

    return 1;
}

# Called by Perl at the time of processing 'use' but _not_ of processing 'require'

sub import {
    my $class = shift;    # Getopt::Auto
    #$DB::single = 2;     ## no critic (ProhibitPackageVars)

    my @caller = caller;
    pop @caller;

    my $opt = "$caller[0]::options";
    if ( not defined $opt ) {

        # Which may not exist either, but that's OK.
        $opt = q{main::options};
    }

    # So it's easy to turn off the trace from the environment
    if ( exists $ENV{'GETOPT_AUTO_TRACE'} ) {
        $config{'trace'} = $ENV{'GETOPT_AUTO_TRACE'} == 1 ? 1 : undef;
    }

    my $ctls;
    while ( my $arg = shift ) {
        if ( ref $arg eq 'HASH' ) {
            foreach my $opt ( keys %{$arg} ) {
                if ( exists $config{$opt} ) { $config{$opt} = 1; }
                else {
                    _error(qq{Option '$opt' is unknown});
                }
            }
            $ctls = $arg;
        }
        elsif ( ref $arg eq 'ARRAY' ) {
            $ctls = {};
            _check_spec( $arg, [ \@caller, $opt, $ctls ] );
        }
        else {
            _error(
                qq{Must be use-d with: no args, an HASH ref or an ARRAY ref}
            );
            return;
        }
    }

    #$config{'trace'}  = 1; # debugging
    push @callers, [ \@caller, $opt, $ctls ];
    _trace("Tracing ...");
    _trace("Package: $callers[-1][0][0], File: $callers[-1][0][1]");
    return;
}

sub _option_type {
    my $option = shift;
    return $BARE if not defined $option;
    $option =~ m{\A$DDASH}smx and return $LONG;
    $option =~ m{\A$DASH}smx  and return $SHORT;
    $option =~ m{\A\w}smx     and return $BARE;
    return $BARE;
}

# Process the files in the script looking for option registrations
# and build the global @spec array

sub _parse_pod {

    foreach my $caller_local (@callers) {

        # We're doing magic!

        # Do the parsing. The -want_nonPODs causes Pod::Parser (the base) to
        # call the preprocess_line() sub with all input, so we can scan for
        # an assignment to $VERSION. Overhead is negligable.

        # The $caller global is used indirectly by PodExtract, via _check_func()
        $caller = $caller_local;

        my $pod = Getopt::Auto::PodExtract->new( -want_nonPODs => 1 );

        my $filename
            = File::Spec->rel2abs( $caller_local->[0][1] );
        my ( $name, $path, $suffix )
            = fileparse( $filename, qw( .t .pm .pl ) );
        my @filenames = $filename;

        # Add a possible POD extra file
        push @filenames, "$path$name.pod";

        foreach my $file (@filenames) {
            _trace("Processing POD in: $file");
            if ( not -r $file ) {
                _trace("$file not readable");
                next;
            }

            # Pod::Parser method that does the work,
            # calling the functions that fill 'funcs'
            $pod->parse_from_file( $file, '/dev/null' );
            last if defined $pod->{'funcs'};
            _trace("No POD in $file");
        }

        if ( not defined $pod->{'funcs'} ) {

          # Strangely, this is OK. _parse_args checks for would-be option subs
            _trace( "No POD in " . join $SPACE, @filenames );
            return;
        }

        # Now move what the POD processing found into a useful format.
        # $pod ($self in Getopt::Auto::PodExtract subs) has, if we've found
        # any =item or =head[2|3|4] lines that parse out as being option
        # registrations.
        
        # This code builds the @spec global array as a stack of spec definitions
        # which will be used later on in option processing.
        #
        # Correction 1.9.0 => 1.9.2 courtesy of Bruce Gray
        my @this_spec;
        foreach my $n ( sort keys %{ $pod->{'funcs'} } ) {
            my $spec = $pod->{'funcs'}{$n};

            if ( exists $spec->{'longhelp'} ) {
                $spec->{'longhelp'} =~ s{\n+\z}{\n}smx;
            }
            push @this_spec,
                [
                $n,                  $spec->{'shorthelp'},
                $spec->{'longhelp'}, $spec->{'code'}
                ];
        }

        _load_options( \@this_spec, $caller_local );

        # Global list '@spec' is assigned here
        push @spec, @this_spec;
    }

    return;
}

sub _set_option {
    my ( $arg, $caller_local ) = @_;

    my ( $opt, $pkg );

    # This is sort of backwards.
    # If the arg is known to be a registered option,
    # then we don't need the caller.
    # Otherwise, $caller_local is used to determine options and package.

    if ( defined $caller_local ) {
        $opt = qq{$caller_local->[1]};
    }
    else {
        $opt = $options{$arg}{'options'};
    }
    # At this point $opt is the hash defined by "our %options" (or main::options)
    # in the _user's_ code. That's a different entity form %options in this code
    # which saves the registration info we collected by parsing the POD

    # This is true for our --help and --version
    if ( not defined $opt ) { return 0; }

    # Warning -- if opption_type is BARE, this should only be called if the
    # op -- arg is registered.
    _trace("Bumping $opt for $arg");
    no strict 'refs';    ## no critic (ProhibitNoStrict)
    # And here we bump the use count for the option
    ${$opt}{$arg}++;

    return 1;
}

sub _split_arg {
    my ( $arg, $args ) = @_;

    if ( defined $config{'nobundle'} ) {
        $args->{$arg} = 1;
        return $arg;
    }

    # This applies only to SHORT options
    if ( _option_type($arg) != $SHORT ) { return $arg; }
    if ( length $arg == 2 )             { return $arg; }

    # Builtin help/version meets this criteria
    if (    ( exists $options{$arg} )
        and ( exists $options{$arg}{'registered'} ) )
    {
        return $arg;
    }

    _trace("Splitting $arg into its components");

    my @args;
    foreach my $char ( split m{}smx, substr $arg, 1 ) {
        $char = "-$char";
        push @args, $char;
        $args->{$char}++;
        $args->{$arg}++;
    }
    return @args;
}

sub _is_registered {
    my $arg = shift;

    return ( ( exists $options{$arg} )
        and ( exists $options{$arg}{'registered'} ) );
}

sub _notreg {
    my $text = shift;
    if ( defined $config{'oknotreg'} ) { return; }
    _error(qq{$text is not a registered option});

    if ( defined $config{'nohelp'} ) { return; }
    
    # Make an attempt to add useful info
    # If user has not provided help, this will be the builtin version
    if ( exists $options{'--help'}{'code'} ) {
        _do_option_action('--help');
        return;
    }

    # If user has not provided help, this will be the builtin version
    if ( exists $options{'-h'}{'code'} ) {
        _do_option_action('-h');
        return;
    }

    # Well get here iff the user has provided non-fatal help
    # Or, 'test' is configured
    return;
}

sub _do_option_action {
    my ( $arg, $arg_eq ) = @_;

    if ( defined $options{$arg} ) {

        # Registered option
        # Check for sub to execute
        if ( exists $options{$arg}{'code'} ) {
            _trace("Running code $options{$arg}{'code'}");
            no strict 'refs';    ## no critic (ProhibitNoStrict)
            $options{$arg}{'code'}->();
            return 1;
        }

        # No sub, registered option, so assign %options
        # unless it's an assignment-type option, which must have a sub
        if ( defined $arg_eq ) { return 0; }

        _set_option($arg);
        return 1;
    }
}

sub _check_help {
    my @perfs;
    foreach my $op ( keys %options ) {
        if ( exists $options{$op}{'restrict'} ) { next; }
        $perfs[ _option_type($op) ]++;
    }

    $help_p = $LONG;
    my $max_p = 0;
    foreach my $i ( $BARE .. $LONG ) {
        if ( ( defined $perfs[$i] ) && ( $perfs[$i] > $max_p ) ) {
            $help_p = $i;
        }
    }

    my $help = "$PREFIXES[$help_p]help";
    my $vers = "$PREFIXES[$help_p]version";
    if ( not exists $options{$help} ) {
        $options{$help}{'code'}       = \&_help;
        $options{$help}{'registered'} = 1;
        $options{$help}{'shorthelp'}  = 'This text';
    }
    if ( not exists $options{$vers} ) {
        $options{$vers}{'code'}       = \&_version;
        $options{$vers}{'registered'} = 1;
        $options{$vers}{'shorthelp'}  = 'Prints the version number';
    }

    return;
}

my @not_option;

sub _not_option {
    my ( $arg, $eq ) = @_;

    # The param $eq indicates that we're undoing an arg of the
    # form -foo=22. The 22 is in @ARGV, but there was no sub
    # to consume it, so we move it off.
    if ( defined $eq ) { $arg .= qq{=$eq}; shift @ARGV; }
    push @not_option, $arg;
    return;
}

sub _parse_args {    ## no critic (ProhibitExcessComplexity)
    @not_option = ();

    _trace_argv();

    # Check that builtin help is defined according to the option type
    _check_help();

    # Check each script/module for an init sub to execute
    # If the user has defined one, its in the @callers array at [2].
    foreach my $caller_local (@callers) {
        my $init_sub = $caller_local->[2]{'init'};
        if ( defined $init_sub ) {
            _trace("Executing code for init_sub");
            no strict 'refs';    ## no critic (ProhibitNoStrict)
            $init_sub->();
        }
    }

    while ( my $argv = shift @ARGV ) {

        my $op_type = _option_type($argv);

        _trace("Considering $argv, option type is $TYPES[$op_type]");
        _trace_argv();

        # Check cease and desist
        if ( $argv =~ m{\A-{1,2}\z}smx ) {
            _trace("Option end $argv, scanning ends");

            # Marker is not replaced
            last;
        }

        # Check restricted option
        if ( _is_restricted($argv) ) {
            _trace("Option $argv is restricted, skipping");
            _not_option($argv);
            next;
        }

        # Check --foo=bar syntax use
        my $arg_eq;
        if ( $argv =~ m{=}smx ) {

            # Assign-type option: --foo=bar
            ( $argv, $arg_eq ) = split m{=}smx, $argv;
            unshift @ARGV, $arg_eq;
            _trace("Option $argv has assignment");
            _trace_argv();
        }

        # Process $argv as directed by %options, or push it back onto @ARGV

        if ( _is_registered($argv) ) {

            # Registered option, the simple case
            if ( _do_option_action( $argv, $arg_eq ) ) { next; }

            # _do_option_action returns 0 iff $arg_eq and no sub
            _error(qq{To use $argv with "=", a subroutine must be provided});
            _not_option( $argv, $arg_eq );
            next;
        }

        _trace("$argv is not registered");

        # Well, what we have in $argv is not registered

        if ( defined $config{'findsub'} ) {
            my $sub = _check_all_sub($argv);
            if ( defined $sub ) {
                _trace("Running code $sub");
                no strict 'refs';    ## no critic (ProhibitNoStrict)
                $sub->();
                next;
            }
            if ( _do_option_action( $argv, $arg_eq ) ) { next; }
        }

        # $argv is not registered.
        # Perhaps its a concatiation of single-letter SHORTs?
        if ( ( $op_type == $SHORT ) && ( length $argv > 2 ) ) {
            my %args;
            my @args = _split_arg( $argv, \%args );

            foreach my $arg (@args) {
                if ( _is_registered($arg) ) {
                    _do_option_action($arg);
                    $args{$arg}--;
                    $args{$argv}--;
                }
                else {
                    _trace("$arg is not registered");
                }
            }

        # Generate error messages for unregistered arg(s)
        # $argv is not registered iff _none_ of its components are registered
        # We know this because none of the components caused a decrement above
            if ( $args{$argv} == @args ) {
                _notreg($argv);
                _trace("$argv is not an option");
                _not_option( $argv, $arg_eq );
                next;
            }

            # Report all components of $argv that are not registered
            foreach my $arg (@args) {
                if ( $args{$arg} == 0 ) { next; }
                _notreg(qq{$arg (from $argv)});
                _trace("$arg is not an option");
                _not_option($arg);
            }
            next;
        }

        # Provide a warning for non-bare options
        if ( $op_type != $BARE ) { _notreg($argv); }

       # Save an element of @ARGV that did not meet the criteria for an option
        _trace("$argv is not an option");
        _not_option( $argv, $arg_eq );
    }

    # Give the user what's left
    unshift @ARGV, @not_option;
    _trace("Scanning ends");
    _trace_argv();

    return;
}

sub _sort_sub {
    my ( $A, $B ) = ( $a, $b );
    $A =~ s{\A-*}{}smx;
    $B =~ s{\A-*}{}smx;
    return $A cmp $B;
}

sub _version {
    print STDERR "This is $callers[0][0][1]";
    if ( defined $their_version and length $their_version ) {
        print STDERR " version $their_version";
    }
    else {
        print STDERR " (no version is specified)";
    }
    print STDERR "\n\n";
    return;
}

sub _help {
    _version();

    # Are we being asked for *specific* help?
    if ( my @help = grep { exists $options{$_} } @ARGV ) {
        my $what = shift @ARGV;
        if ( exists $options{$what}{'shorthelp'} ) {
            print STDERR 
                "$callers[0][0][1] $what - $options{$what}{'shorthelp'}\n\n";
            if ( defined $options{$what}{'longhelp'} ) {
                print STDERR $options{$what}{'longhelp'}, "\n";
            }
        }
        else {
            print STDERR "No help available for $what\n";
        }
    }
    else {

        my $and_there_s_more = 0;
        foreach ( sort _sort_sub keys %options ) {
            print STDERR "$callers[0][0][1] $_";
            if ( defined $options{$_}{'shorthelp'}
                and ( $options{$_}{'shorthelp'} =~ m{\S}smx ) )
            {
                print STDERR " - $options{$_}{'shorthelp'}";
            }
            if ( defined $options{$_}{'longhelp'}
                and ( $options{$_}{'longhelp'} =~ m{\S}smx ) )
            {
                $and_there_s_more++;
                print STDERR q{ [*]};
            }
            print STDERR "\n";
        }

        if ($and_there_s_more) {
            print STDERR <<"EOF";

More help is available on the topics marked with [*]
Try $callers[0][0][1] $PREFIXES[$help_p]help $PREFIXES[$help_p]foo
EOF
        }
    }
    print STDERR qq{This is the built-in help, exiting\n};
    if ( not defined $config{'test'} ) { exit 0; }
    return;
}

1;

# This package exists to provide replacement for the default subs (of the same name)
# provided by Pod::Parser
# The way it works is that they are called at appropriate times to extract the
# information we need to support the options.
# The sub names are determined by Pod::Parser, so don't meddle.

## no critic (ProhibitMultiplePackages)
package Getopt::Auto::PodExtract;
use base 'Pod::Parser';

## no critic (ProtectPrivateSubs)

# Called when Pod::Parser finds '^=...'
sub command {
    my ( $self, $command, $text, $line_num ) = @_;

    # Cancel text grabs; whatever we've got, we've got.
    $self->{'copying'} = 0;

    # Process only "=item" and "=head2, =head3 and =head4"
    if ( $command eq 'item' || $command =~ m{^head(?:2|3|4)}smx ) {

        # Sometimes more han one newline, which I don't understand
        while ( chomp $text ) { }

        Getopt::Auto::_trace("Parsing =$command $text");

        my $shorthelp;
        $text =~ s{\s+-+\s+(.*)}{}smx;
        if ( defined $1 ) {
            $shorthelp = $1;
        }

        # No qualifying dash, or no space after dash
        # The RE fails, leaving $t unchanged
        if ( not defined $shorthelp ) {
            Getopt::Auto::_trace('No shorthelp, not an option');
            return;
        }

        Getopt::Auto::_trace("Shorthelp is: $shorthelp");

        # This suports options of the form "-f, --foo"
        my $sub;
        my @nosub;
        my @opts = split m{,\s*}smx, $text;
        foreach my $name (@opts) {
            $name =~ s{\A(\w<)?([\w_-]+)>?}{$2}smx;
            if ( $name =~ m{\s}smx ) {
                Getopt::Auto::_trace("$name dropped, has spaces");
                next;
            }

            Getopt::Auto::_trace("Option is $name");
            $self->{'funcs'}{$name} = { 'shorthelp' => $shorthelp, };
            $self->{'copying'}      = 1;
            $self->{'latest'}       = $name;
            my $sub_found = Getopt::Auto::_check_func($name);
            if ( defined $sub_found ) {
                $self->{'funcs'}{$name}{'code'} = $sub_found;
                $sub = $sub_found;
            }
            else {
                push @nosub, $name;
            }
        }

        # Options that had no defined sub get the last-defined sub
        foreach my $name (@nosub) {
            $self->{'funcs'}{$name}{'code'} = $sub;
        }
    }
    return;
}

# Called when text that begins with spaces (or tabs) is discovered inside POD text.
# As implied by the name, verbatum text is taken 'as is'.
# We save it only if we're inside of =item or =head ($self->{copying})

sub verbatim {
    my ( $self, $paragraph, $line_num ) = @_;
    if ( $self->{'copying'} ) {
        $self->{'funcs'}{ $self->{'latest'} }{'longhelp'} .= $paragraph;
        Getopt::Auto::_trace("verbatim - longhelp is: $paragraph");
    }
    return;
}

# Called when text that does not begin with spaces (or tabs) is discovered inside POD text.
# The semantics of text blocks require that 'interior sequences' (e.g.: B<foo>) be expanded.
# That's what the Pod::Parser sub interpolate() does.
# We save it only if we're inside of =item or =head ($self->{copying})

sub textblock {
    my ( $self, $paragraph, $line_num ) = @_;
    if ( $self->{'copying'} ) {
        $self->{'funcs'}{ $self->{'latest'} }{'longhelp'}
            .= $self->interpolate( $paragraph, $line_num );
        Getopt::Auto::_trace("textblock - longhelp is: $paragraph");
    }
    return;
}

sub preprocess_line {
    my ( $self, $text, $line_num ) = @_;

    defined Getopt::Auto::_get_their_version() and return $text;

    if ( $text =~ m{\$VERSION}smx ) {
        my ($tv) = $text =~ m{([\d\.]+)}smx;
        Getopt::Auto::_set_their_version($tv);
        Getopt::Auto::_trace("Extracted version $tv from $text");
    }
    return $text;
}

1;

__END__

=pod

=begin stopwords

CVS
Hah
executables
argA
unshifted
useing
init
Perldb
STDERR
args
INIT
Pagaltzis
Tegbo
Forgetaboutit
Pre

=end stopwords

=head1 NAME

Getopt::Auto - Option framework for command-line applications

=head1 SYNOPSIS

    use Getopt::Auto;

=head1 DESCRIPTION

C<Getopt::Auto> provides an easy way to organize a script
to handle whatever option mechanism it requires. 

For each option C<--foo> you provide a subroutine C<sub foo{...}>.
The sub is called every time C<--foo> appears on the command line.
Values for the option are taken from C<@ARGV>.

If you don't provide a subroutine for C<--foo>, then C<$options{'--foo'}>
is set.


=head2 Using Getopt::Auto

=over 4

=item *

In the POD (Plain Old Documentation).

=item *

In the B<use> statement.

=item * 

Forgetaboutit.

=back

=head2 Example

Here's an example I'll reference later.

    use Getopt::Auto;
    our %options;

    $VERSION  = '1.0';
    sub add { $count += shift @ARGV; }
    $count += $options{'--inc'};
    print "Count: $count\n";

    =pod

    =head2 -a, --add - Add integer to count.

    The integer argument is not checked.

    =head2 --inc - Bump count by 1

    =cut

When C<example.pl> is executed,

    example.pl --add 2 --inc -a 3
    Count: 6

=head2 Working from POD

OK, so we're all excellent Perl authors, which means that our scripts have careful
and extensive documentation as POD. In particular all of the options are there.
Just check that the options are described in one of these ways, and you 
can enjoy all of the benefits of C<Getopt::Auto>.

Use C<=head2>, C<=head3>, C<=head4> or C<=item>, thus:

    =head2 -a, --add - Add integer to count.

    The integer argument is not checked.

There are several things to note.

=over 4

=item *
    
I've used C<=head2> in the example.

Wherever I do this, you may
substitute C<=head3>, C<=head4> or C<=item> as you wish. 
    
=item *

Notice the structure of the C<=head2> line. It's important.

To begin, we have the options C<-a> and C<--add>. There are some
options (pun intended) here. Three styles are supported, and they may be
mixed. 

=over 4

=item "long" (C<--gnu-style>)

=item "short" (C<-oldstyle>)

=item "bare" (CVS-style, C<myprogram edit foo.txt>)

=back

What follows the option(s) is 'I<space(s) dash(es) space(s)>'; at a minimum ' - '.
This makes the C<=head2> command into an option registration. Without it, it's 
just another C<=head2>.
The 'dash space' separates the option from the remainder of the line,
which is called the L</Short Help>. If there's just 'I<space dash space>' and nothing
else, then there is no L</Short Help>.

Options may be combined.  For example, C<=head2 -a, --add>.

=item *

Finally, there's the L</Long Help>. There may be one or more paragraphs, or 
there may be none. It's up to you. The L</Long Help> stops at the next POD command.

=back

The L</Short Help> and L</Long Help> are used by the built-in C<--help> option.
See L</Help and Version>.

=head2 use Getopt::Auto([...])

C<Getopt::Auto> can work from lists passed in the B<use> statement.
It expects a reference to a list of lists. Each list consists of four 
elements.

=over 4

=item *

The name of the option, with the requisite leading dashes, if any

=item *

The short help. One line, no newlines

=item *

The long help, paragraphs separated by newlines

=item *

A CODE reference for the subroutine that processes the option

=back

The L</Example> could be coded with no POD.

    use Getopt::Auto([
                      ['--add', 'Add integer to count.', "The integer argument is not checked.
                      ['-a', 'Add integer to count.', undef, \&add],
                      ['--inc','Bump count by 1', undef, undef]
                     ]);

There is no requirement that the CODE reference have the same name
as the option, nor that it be unique. It can also be C<undef>
if you wish only to have C<%options> set.  
The command line is treated the same irrespective of how the 
options are defined.  Please use C<undef> for any list elements you don't need.

You may have multiple [] groupings, and you may also include L</Advanced Options>.
However, you may I<not> use a variable, because a variable won't be assigned at 
the time C<Getopt::Auto::import> is called.

This method can be used in conjunction with L</Working from POD>.

=head2 Forgetaboutit

This feature must be turned on using the 
L</Advanced Usage> configuration option, C<findsub>.

So, you're not so careful about your POD? Or, perhaps its too soon for POD? (Hah!)
Never fear, you're covered. Just provide an option subroutine, or check C<%options>.
This works because when C<Getopt::Auto> comes across what appears to be an option 
while processing the command line, it checks to see if there's a corresponding sub.
If you have a sub whose name is the same as a piece of valid I<data> that may
be entered on the command line, the data will be treated as an option, so be careful.

=head2 Where's the POD?

C<Getopt::Auto> looks for POD in three places, in this order:

=over 4

=item The current file

=item Thie current file with the extension '.pod' substituted for .pm, .pl or .t.

=item The current file with the extension '.`pod' added, if there's no  .pm, .pl or .t.

=back

Scanning stops the first time there is I<any> success. 
This means that you can't split  the C<=head2> POD over files.
Notice that although we talk about C<example.pl>, all of this
works for C<example.pm> as well. Or  C<example.t>, for that matter.

There's a (small) exception to this. Scanning for VERSION 
does not interrupt the scanning for POD. See L</Help and Version>.

It's OK for there to be no POD at all, so there's no error message if,
for example, your foo.pl has no POD and there's no foo.pod.

=head2 What's an Option?

Here's our example, once more.

    =head2 -a, --add - Add integer to count.

    The integer argument is not checked.

C<Getopt::Auto> scans your script (In the C<CHECK> block: see L<perlmod>).
Once the C<=head2> is stripped, we're left with a line of text. 
Some options (C<-a, --add>),
followed by 'I<space(s) dash(es) space(s)>'; at a minimum ' - '.
This makes the C<=head2> command into an option registration. Without it, it's 
just another C<=head2>.
Notice that there are two options here, one short and one long, seperated by a
comma. You can have more than just two. Or just one.

C<Getopt::Auto> checks to see if there's a subroutine in the
current package that is defined for each option. See L</Option Subroutines>.

It's not a requirement that every option have a subroutine.
See L</Options Without Subroutines>.

If, in the example, there's no C<sub a{...}>. In order to simplify things for you,
C<Getopt::Auto> assumes that if you are listing several options under a
single C<=head2>, you probably wish to process them with the same sub.
Hence, any options that don't have a C<sub> are assigned the I<next> one found that does.
C<sub add{...}> in the example.

The 'dash space' separates the option from the remainder of the line,
which is called the L</Short Help>. If there's just 'I<space dash space>' and nothing
else, then there is no L</Short Help>.

=head3 Short Help

The short help is everything on the line after "dash space".
If it's not defined, then this C<=head2> does not describe an option.

=head3 Long Help

The paragraph(s) that follow the C<=head2> up to the 
next POD command are the long help. There may be none.
The long help is copied verbatim from the POD, without formatting.

=head3 Registered Option

Options discovered in POD are referred to as I<registered>,
Options from L</use Getopt::Auto([...])> are also I<registered>.
Otherwise, anything on the command line that I<looks> like an option
will get an error message. These are called I<unregistered> options.

=head2 Option Subroutines

The name of an option subroutine is computed from the name of the option.

=over 4

=item *

Strip leading dashes

=item *

Convert embedded dashes to underscores

=back

C<--foo-bar> expects C<sub foo_bar{...}>.

=head2 Command Line Processing

Now we've scanned the POD and/or included the data from
C</use Getopt::Auto([...])>.
C<Getopt::Auto> sees C<@ARGV> before the program begins execution.
(In the C<INIT> block: see L<perlmod>.)
As it processes the elements, it finds options and executes the 
indicated actions.
The non-option elements are shifted off and retained. 
The processing subroutines may manipulate C<@ARGV> in any way,
but it's expected that they will just shift off their arguments,
which will be the first elements of C<@ARGV>.
When option processing ends, the retained elements are
replaced (unshifted) for the program to see.

So, using L</Example> again, when
C<example.pl --add 2 9999 --inc -a 3 abcd>, 
begins execution, 
it sees C<(9999, abcd)> in C<@ARGV>, 2 and 3 having been shifted off by add().

=head3 Values specified by "="

This would be C<--add=24> rather than C<--add 24>.
If C<Getopt::Auto> encounters this construct, it strips out
the "=" and C<add()> will see "24" in C<$ARGV[0]>.
Note that as this usage provides an argument, there I<must> be a 
subroutine associated with the option.

=head3 Cease and desist

There's a convention in C<@ARGV> processing that uses a bare "--" or "-" to signal 
the end to option processing. C<Getopt::Auto> supports this, and you can use either!

    example.pl --add 2 -- 9999 --inc -a 3 abcd 

leaves C<(9999 --inc -a 3 abcd)> in C<@ARGV>. 
Command-line processing was turned off by the '--' that follows C<--add 2>.

=head3 Execution Order

When coding an option subroutine, take into consideration that it will be
executed in the context of an C<INIT> block. (See L<perlmod>.) A side-effect of this (or the 
intended effect, if you prefer) is that none of what one might see as
"normal" variable initializations are performed.  For example, add this to example.pl:

    my $var = 'abcd';
    sub printvar {
        print "\$var is '$var'\n";
    }

    =head2 --printvar - Print the value of $var

and so,

    example.pl --printvar
    $var is ''

as C<$var> is undefined at that point.

It's easy to get caught by this, especially when converting code from other
option schemes. There are ways to work around the problem.

=over 4

=item Use write-only subroutines

This is general advice for option subroutines. Think of them as write-only. 
In other words, they should not I<read> anything from their environment,
other than C<@ARGV>.
 
=item Use a flag variable

Have foo() set a "foo was called" global (not initialized, of course) and call foo()
(now renamed) at a convenient time. 

=item Don't use a C<sub foo> for C<--foo>

At a convenient time do: C<_foo() if exists $options{'--foo'}>. 

=item Use an C<init> subroutine.

If the L</Configuration> hash has C<init =E<gt> \&your_init_sub>, then C<your_init_sub> will be
called at the in the C<INIT> block I<before> any option processing. Needed initializations
could be performed there. 

=back

=head3 Options Without Subroutines

An option that does not have an associated subroutine
will cause C<$options{'option'}> in the B<use>-ing package to be incremented.
(Please specify "B<our> %options") and note the quotes. The option is inserted in
the C<%options> hash as C<--add> or C<-a>. Omit the quotes and Perl will try to pre-increment
your C<sub add{...}>!

A note about interaction with your code.

=over 4

=item If you say C<our %options>

The hash will be managed as above.

=item If you say nothing

You'll get a C<%main::options> defined for you. If you use C<%options> in other ways, 
that could result in confusion.

=item If you say C<my %options>

C<%main::options> will be assigned as above, and will be accessible (unless you C<use strict>)
until your C<my %options> is executed.

=back


=head3 Mixing Option Styles

C<Getopt::Auto> is tolerant of mixed bare, short and long option styles.
There's one thing to look out for. If you say C<-foo> when you registered C<--foo>,
you will I<not> get a call to sub foo(). Instead, you get the
default processing for short options.

=head3 Short Option Default Processing

If C<-foo> is not L<Registered> 
C<Getopt::Auto> treats C<-foo> as one use of C<-f> and two of
C<-o>.
So the processing looks for C<sub f{...}> and C<sub o{...}>.
If they are defined, they are called. Otherwise,
you will find C<$options{'f'} == 1>, and C<$options{'o'} == 2> in
the calling package.

Now, if this was not sufficiently complicated, immagine if you executed C<example.pl>
as C<example.pl -fad>. C<-fad> is an unregistered, short option. So, in addition to
complaints about C<-f> and C<-d> not being registered options (see L</Option Errors>),
C<sub add> will be executed because of the default processing for C<-fad>. You can 
use L</Tracing> to follow the workings of this case. One more thing. Because C<-fad>,
C<-f> and C<-d> did not have an associated subs, they will all show up in C<@ARGV>.

All of this complexity may be avoided by selecting the L</Configuration> option 
C<nobundle>.

=head2 Invalid Options

Options, (short or long) that 
are not registered 
are unshifted into C<@ARGV>.
There will also be an error message. See L</Option Errors>.
Bare "options" are indistinguishable from command-line data, so they can't
be flagged as errors.

=head2 Advanced Usage

=head3 Configuration

C<Getopt::Auto> may be invoked with an hash ref. These are the recognized keys,
also referred to as "Configuration Options". Note that I<with the exception of init>
all of the options are I<global>, in the sense that they are executed processing the
command line so in which module they might have been specified is irrelevant.

=over 4

=item *

C<noshort =E<gt> 1> - Ignore short options

=item *

C<nolong =E<gt> 1> - Ignore long options

=item *

C<nobare =E<gt> 1> - Ignore bare options

=item *

C<nobundle =E<gt> 1> - Don't de-group short options

=item *

C<nohelp =E<gt> 1> - Don't provide help for unregistered options

=item *

C<oknotreg =E<gt> 1> - Do not complain if unregistered options are found on the command line

=item *

C<okerrors =E<gt> 1> - Do not exit if there are errors parsing C<@ARGV>)

=back

=over 4

=item *

C<init =E<gt> \&your_sub> - Called before processing command line

This subroutine will be called by C<Getopt::Auto> in the C<INIT> block
before it scans the command line
for options. If multiple packages are involved, the init subroutines are executed in
the order processed by Perl.

=item *

C<findsub =E<gt> 1> - Enable using unegistered options

If C<--foo> is not registered but there is a C<sub foo{...}>, it will be called.
This implies C<oknotreg =E<gt> 1> .

=item *

C<trace =E<gt> 1> - Enable tracing.

=back

=head3 Restricted

If an option style is turned off by one of C<noshort>, C<nolong> or C<nobare>, it is referred to
as I<restricted>.

=head3 Tracing

Setting the environment variable C<GETOPT_AUTO_TRACE> to 1 with cause C<Getopt::Auo>
to trace its actions to C<STDOUT>. If you say C<trace =E<gt> 1> in the configuration hash, 
this overrides C<GETOPT_AUTO_TRACE>. To turn off tracing from the shell, set
C<GETOPT_AUTO_TRACE> to 0. 

=head3 Debugging

C<Getopt::Auto> runs before your script starts. So what if you need to debug it?
You will notice several lines in the code:

    #$DB::single = 2;      ## no critic (ProhibitPackageVars)

Delete the '#' to have the Perl debugger stop at that point. So why are these lines
commented out? So you won't have to step over them when debugging your script.

Despite this, when you load your script in the Perl debugger, you will see:

    _parse_args();

Why is this? Because this part of C<Getopt::Auto> is actually the first part of your
script, as it's in the C<INIT> block.
At this point, you're in F<Getopt/Auto.pm>, not the file you're attempting to debug.
So, just enter 'c' to continue from the C<INIT> block,
and you're on your way. 
To set breakpoints in your code, either use the Perldb C<f> command to move focus to the
appropriate source file, or use the Perldb commands 
C<n> or C<r>, which will take you to the first executable
statement in the code that B<use>s C<Getopt::Auto>. 
Sorry for the inconvenience.

=head3 Extended Example

Check out F<scripts/tour.pl> in the distribution for an extended example.

=head2 Help and Version

C<Getopt::Auto> automatically provides C<help> and C<version> options,
following  the style (long, short or bare) that is (numerically) the most common
in the POD or the B<use> statement. And if there's no POD? Then the default is
to recognize C<--help> and C<--version>.

C<help> and C<version> are output to STDERR.

C<--help> lists the commands available and the short help messages. If a
C<--help --option> is given for a option with L</Long Help>, the
longer message will be printed instead. Of course options discovered by C<findsub> 
won't appear.

C<--version> displays your program name, plus C<VERSION>. This
means you must set C<$VERSION = whatever> in your application.
(It's not a problem if you don't).
C<Getopt::Auto> gets this by scanning the calling package for the first occurrence
of C<$VERSION>, and then extracts a version number matching C<[\d\.]+>.
If you have another standard, well ....

The help function will C<exit 0> after execution.

    example.pl --help

    This is example.pl version 1.0

    example.pl -a - Add integer to count.
    example.pl --add - Add integer to count. [*]
    example.pl --help - This text
    example.pl --inc - Bump count by 1
    example.pl --version - Prints the version number

    More help is available on the topics marked with [*]
    Try example.pl --help --foo
    This is the built-in help, exiting

Suppose you want to have your own C<--help> and/or C<--version>? An obvious way to do the
would be to check C<$options{'--help'}> in your script. Regrettably, there's a conflict
between this way of doing things and the built-in help. However, if you create a C<sub help{...}>
instead, it will work fine.

L<Pod::Usage> does a nice job of turning your POD into help.

Here's a simple usage().

=over 4

    sub usage {
        pod2usage( -verbose => 2 );
        exit 0;
    }

=back

=head1 ERRORS

C<Getopt::Auto> tries not to complain, but sometimes life is just too hard!
Output is to STDERR. 

=head2 From use Getopt::Auto

These happen when the C<import> method has a problem.
No additional processing by C<Getopt::Auto> takes place.
C<Getopt::Auto> will C<exit 1> before parsing the POD.

=over 4

=item *

Getopt::Auto: Option specification [list element] should be a reference

We need either a reference to an HASH or ARRAY.

=item *

Getopt::Auto: Option list is incompletely specified

It needs 4 elements. See L</use Getopt::Auto([...])>.

=item *

Getopt::Auto: Must be use-d with: no args, an HASH ref or an ARRAY ref

Whatever you said, it wasn't one of these.

=item *

Getopt::Auto: Option E<lt>optionE<gt> is unknown

You've said something like C<use Getopt::Auto({foobar=>1})>,
and we don't know about C<foobar>.

=back

=head2 From C<@ARGV> Processing

If there are any errors in this phase, C<Getot::Auto> will C<exit 1>
at the end of processing I<unless> you have set the L</Configuration>
option C<okerror>. The number of errors may be obtained by calling
C<Getopt::Auto::get_errors> (which is not exported).

=over 4

=item *

Getopt::Auto: E<lt>optionE<gt> is not a registered option

C<Getopt::Auto> has found E<lt>optionE<gt> (C<--foobar>) on the command line, but you did 
not make it a L</Registered Option>. If this is the way you like to do things, you need to 
C<use Getopt::Auto({oknotreg=>1}).

If you have an unregistered option, you will also get help, if it is available.
This means the subroutine that you specified for --help, for -h or the builtin
help if neither are available. To avoid all of this, say C<use Getopt::Auto({nohelp=>1}).

Getopt::Auto: E<lt>optionE<gt> (from E<lt>some optionE<gt>) is not a registered option

C<Getopt::Auto> has found E<lt>optionE<gt> (C<-foo>) on the command line, but you did 
not make it a L</Registered Option>.
However, there were some subs defined, so there was partial execution.
Notice that the example refers to a I<short> option, as this situation can only
happen there. Suppose you defined C<sub o{...}> but not C<sub foo{...}>.
The default processing for a short option that does not have an associated sub is
to examine the individual letters. In this case, C<sub o{...}> was found, and 
executed. The error message will report C<-f> from C<-foo> as unregistered.

Again, if this is the way you like to do things, you need to 
C<use Getopt::Auto({oknotreg=>1}).

=item *

Getopt::Auto: To use E<lt>optionE<gt> with "=", a subroutine must be provided

The only way to interpret "--foo=24" is that a sub foo{...} exists that will
extract "24" from C<@ARGV>.

=back

=head1 INCOMPATIBILITIES

C<Getopt::Auto> may be B<require>d, but as it depends on Perl calling its
C<import()> subroutine to process arguments to the statement, none of these
will work. Of course, if you use C<import Getopt::Auto> as well, all will be well.

In version 1.0, the option subroutine is called after the program exits
(in the C<END> block) with the contents of C<@ARGV> at that point as parameters.
C<Getopt::Auto> then exits, meaning that only one option subroutine can be
processed.

In the present version, the option subroutines are called
called I<before> program execution begins (in the C<INIT> block).
The subroutine is called with no parameters. Rather, it is expected
to inspect C<@ARGV> and remove whatever it uses. Multiple 
option subroutine calls are supported.

In the C<END> block, the 1.0 code executes main::default()
if that subroutine is present. This has been retained for compatibility, but will be 
removed in future versions unless someone makes a fuss.

=head1 VERSION

Version 2.0

=head1 AUTHOR

Simon Cozens,
who had the original idea.

=head1 MAINTAINER

Geoffrey Leach L<mailto://gleach@cpan.org>,
who has hacked on it unmercifully.

=head1 THANKS TO

Bruce Gray,
Aristotle Pagaltzis
and
Ian Tegbo
for their contributions. All errors are the responsibility of the maintainer.

=head1 SEE ALSO

L<Config::Auto>, L<Getopt::Long>, L<perlmod>, L<Pod::Usage>

=head1 COPYRIGHT AND LICENSE 

Copyright (C) 2003-2009, Simon Cozens.

Copyright (C) 2010, Geoffrey Leach.

This module is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.For more details, see the full text of the licenses at
L<http://www.perlfoundation.org/artistic_license_1_0>,
and L<http://www.gnu.org/licenses/gpl-2.0.html>.

=cut

