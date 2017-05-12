package Hardware::Vhdl::Tidy;

# TO DO:
#  Tidier directives in source code to set stack
#  setting to control whether we include whitespace at start of empty lines
#  check whether there are any other 'loop' forms
#  put underscore at start of names of internal routines
#  implement PBP generally

use Hardware::Vhdl::Lexer;
use Getopt::Long;
use Carp;
use Exporter 'import';

use strict;
use warnings;

sub parse_commandline;
sub tidy_vhdl_file;
sub tidy_vhdl;

our $VERSION = 0.80;

#our @EXPORT=();
our @EXPORT_OK=qw/ tidy_vhdl_file tidy_vhdl /;

our $debug = 0;

our %default_args = (
    indent_spaces        => 4, # integer value, >= 0
    cont_spaces          => 2, # integer value, >= 0
    tab_spaces           => 0, # integer value, >= 0
    starting_indentation => 0, # integer value, >= 0
    preprocessor_prefix  => '#', # string
    indent_preprocessor  => 0, # boolean
);

sub parse_commandline {
    # parse command-line args
    # for example, for an in-place tidy of a vhd file:
    #   perl -MHardware::Vhdl::Tidy -e "Hardware::Vhdl::Tidy::parse_commandline" -- -b <$file>
    my $inplace = 0;
    my $bext    = '.bak';
    my %args    = %default_args;
    my $result  = GetOptions(
        "b"      => \$inplace,
        "bext=s" => \$bext,
        "i|indentation=i" => \$args{indent_spaces},
        "ci|continuation-indentation=i" => \$args{cont_spaces},
        "t|tab_spaces=i" => \$args{tab_spaces},
        "sil|starting-indentation-level=i" => \$args{starting_indentation},
        "ppp|preprocessor-prefix=s" => \$args{preprocessor_prefix},
        "ipp|indent-preprocessor" => \$args{indent_preprocessor},
    );

    # any args not matched are taken to be input filenames
    for my $afile (@ARGV) {
        if ($inplace) {
            # change in-place: rename the original file and then make the old filename the destination
            rename $afile, $afile . $bext || die "Could not rename $afile: $!\n";
            tidy_vhdl_file( source => $afile . $bext, destination => $afile, %args );
        } else {
            # not in-place: output to STDOUT
            tidy_vhdl_file( source => $afile, %args );
        }
    }

    return;
}

sub tidy_vhdl_file {
    # reads from STDIN if source filename not specified
    # writes to STDOUT if destination filename not specified
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $fhi;
    if ( defined $args{source} ) {
        open $fhi, '<', $args{source} || die "Could not read $args{source}: $!\n";
    } else {
        open $fhi, '-' || die "Could not read from STDIN: $!\n";
    }
    binmode $fhi;
    $args{source} = $fhi;

    my $fho;
    if ( defined $args{destination} ) {
        open $fho, '>', $args{destination} || die "Could not write $args{destination}: $!\n";
    } else {
        open $fho, '>-' || die "Could not write to STDOUT: $!\n";
    }
    binmode $fho;
    $args{destination} = $fho;

    eval {
        tidy_vhdl(\%args);
    };
    if ($@) {
        my $err=$@;
        $err =~ s/ tidy_vhdl /tidy_vhdl_file/xmsg;
        croak $err;
    }
    return;
}

#                   label   is  name    end_t   end_name/label
# entity            n       y   y       o       o
# architecture      n       y   y       o       o
# configuration     n       y   y       o       o
# package [body]    n       y   y       o       o
# function          n       y   y       o       o
# procedure         n       y   y       o       o

# component         n       o   y       y       o
# for (in config)   n       n   u       y       n

# case              o       y   n       y       o
# process           o       o   n       y       o
# if (...then)      o       n   n       y       o
# for (...loop)     o       n   n       y       o
# loop              o       n   n       y       o

# block             y       o   n       y       o
# if (...generate)  y       n   n       y       o
# for (...generate) y       n   n       y       o

# NB: functions can be marked as pure or impure
#   processes can be marked as postponed

sub tidy_vhdl {
    # parse and check arguments
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    croak "tidy_vhdl requires a 'source' parameter"      unless defined $args{source};
    croak "tidy_vhdl requires a 'destination' parameter" unless defined $args{destination};
    for my $opt (keys %default_args) {
        if ( !defined $args{$opt} ) { $args{$opt} = $default_args{$opt} }
    }

    my $output_func;
    {
        my $outobj  = $args{destination};
        my $outtype = ref $outobj;
        if ( $outtype eq q{} ) {
            croak "tidy_vhdl 'destination' parameter is not of a valid type (it is not a reference)";
        } elsif ( $outtype eq 'GLOB' ) {
            $output_func = sub { print $outobj shift }
        } elsif ( $outtype eq 'SCALAR' ) {
            $output_func = sub { $$outobj .= shift }
        } elsif ( $outtype eq 'ARRAY' ) {
            $output_func = sub { push @$outobj, shift }
        } elsif ( $outtype eq 'CODE' ) {
            $output_func = $outobj;
        } elsif (eval {$outobj->can('addtokens')} && !$@) {
            $output_func = sub { $outobj->addtokens(shift) }
        } else {
            croak "tidy_vhdl 'destination' parameter is not of a valid type (type is '$outtype')";
        }
    }

    my $lexer;
    eval {
        $lexer = Hardware::Vhdl::Lexer->new({ linesource => $args{source} });
    };
    if ($@) {
        my $err=$@;
        $err =~ s/ Hardware::Vhdl::Lexer->new /tidy_vhdl/xmsg;
        $err =~ s/ linesource /source/xmsg;
        croak $err;
    }

    my $indent = $args{starting_indentation}; # current indentation level
    my $bracks = 0;   # how many () brackets deep are we?
    my $line = '';    # current line of code tokens (a syntax line, nothing to do with newlines)
    my @stack;        # a list of the indented things we are inside
    my $ln = 1;       # source line num
    my @outline;      # list of tokens to go on the output line
    my ( $token, $type );
    while ( ( ( $token, $type ) = $lexer->get_next_token ) && defined $type ) {
        #print "\n# input token type $type, '".&escape($token)."'\n";
        my $indnext   = 0;
        my $bracknext = 0;
        my $linestart = $line eq '';                  # is this the first token of a syntax line?
        my $toplevel  = @stack ? $stack[0][0] : '';
        my $botlevel  = @stack ? $stack[-1][0] : '';
        if ( substr( $type, 0, 1 ) eq 'c' ) {
            if ( @outline == 0 && $args{preprocessor_prefix} ne '' && substr($token,0,length $args{preprocessor_prefix}) eq $args{preprocessor_prefix}) {
                # this is a preprocessor line: don't attempt to understand it, just emit the whole line unchanged
                my $t;
                while ( ( ( $t, $type ) = $lexer->get_next_token ) && defined $type) {
                    my $lastchar = substr($token, -1, 1);
                    $token .= $t;
                    if ($type eq 'wn') {
                        if ($lastchar eq "\\") {
                            $ln++;
                        }
                        else {
                            last;
                        }
                    }
                }
                $type = 'pp';
            }
            elsif ( $token eq '(' ) { push @stack, [ '(', $ln ]; $indnext = 1; $bracknext = 1 }
            elsif ( $token eq ')' ) { pop @stack; $indent--; $bracks-- }
            elsif ( $bracks == 0 ) {
                my $lctoken = lc $token;
                $line .= ( $lctoken =~ m!^\\.*\\$! ) ? 'xid ' : $lctoken . ' ';

                if ( $lctoken eq ';' ) {
                    if (
                        # configuration spec: 'for' closed by a ';' rather than an 'end'
                        ( $toplevel eq 'architecture' && $line =~ /^for .* : / )
                        # a function declaration is completed by "return <typename>;"
                        || ( $line =~ /^(pure |impure |)function \S+ return .* ; $/ && $line !~ / is / )
                        # a procedure declaration is completed by a ";" after the procedure name and optional parameter list
                        || ( $line =~ /^procedure \S+ ; $/ )
                        # an access type declaration is closed by a ';'
                        || ( $botlevel eq 'type-access')
                      ) {
                        pop @stack;
                        $indnext--;
                    }
                    # semicolon always finishes a syntax line
                    $line = '';
                }

                # standard 'end' completes an indented section
                elsif ( $lctoken eq 'end' && $linestart ) {
                    if ( $botlevel eq 'case=>' ) { pop @stack; $indent--; }
                    pop @stack;
                    $indent--;
                }

                # 'begin' and 'elsif' give a temporary outdent, and finish a syntax line
                elsif ( $lctoken =~ /^(begin|elsif)$/ ) { $indent--; $indnext = 1; $line = ''; $linestart = 1; }
                # 'else' gives a temporary outdent, but check we are in an if/then rather than a "x<=y when..."
                elsif ( $lctoken eq 'else' && @stack && $botlevel eq 'if' ) {
                    $indent--;
                    $indnext = 1;
                    $line    = '';
                }

                # 'is' finishes a syntax line if associated with an indenting token that takes an 'is'
                elsif (    $lctoken eq 'is'
                    && $line =~
                    /^ (entity|architecture|configuration|package|((im)?pure \s )?function|procedure) \s /xms ) {
                    $line = '';
                } elsif ( $lctoken eq 'is' && $line =~ /^(\S+ : )?case / ) {
                    $line = '';
                } elsif (  $lctoken ne 'is'
                    && $line =~ /^ (\S+ \s : \s )?(component|block|(postponed \s )?process) \s (is \s )?\S+ \s $/xms ) {
                    # this is meant to deal with the case where an optional 'is' is missing -
                    #  but it also messes up recognition of component instantiations with the 'component' keyword included
                    $linestart = 1;
                    $line      = $lctoken . ' ';
                }
                # 'loop' finishes a syntax line if associated with an indenting 'for' or 'while'
                elsif ( $lctoken eq 'loop' && $line =~ /^(\S+ : )?(for|while) / ) {
                    $line = '';
                }
                # in a configuration declaration or specification, a 'use' starts a new syntax line
                elsif ( $lctoken eq 'use' ) { $linestart = 1 }
                # 'then' or 'generate' finishes a syntax line
                elsif ( $lctoken =~ /^ (then|generate) $/xms ) { $line = '' }

                # in a configuration declaration, a 'for' always starts a new syntax line and indents,
                #  unless it's an 'end for';
                elsif (    $lctoken eq 'for'
                    && $toplevel eq 'configuration'
                    && $line !~ /^end for $/
                    && $line !~ / end for $/ ) {
                    push @stack, [ $lctoken, $ln, $2 ];
                    $indnext   = 1;
                    $linestart = 1;
                    $line      = 'for ';
                }
                # endable, indenting keywords which start a syntax line (optional label allowed)
                elsif ( $lctoken =~ /^(case|if|for|while|loop)$/ && $line =~ /^((\S+) : )?\S+ $/ ) {
                    push @stack, [ $lctoken, $ln, $2 ];
                    $indnext = 1;
                    if ($lctoken eq 'loop') { $line = '' }
                } elsif ( $lctoken eq 'process' && $line =~ /^((\S+) : )?(postponed )?process $/ ) {
                    push @stack, [ $lctoken, $ln, $2 ];
                    $indnext = 1;
                }

                # code to be executed when a case option is matched
                elsif ( $lctoken eq '=>' && $botlevel eq 'case' && $line =~ /^when / ) {
                    push @stack, [ 'case=>', $ln ];
                    $indnext = 1;
                    $line    = '';
                }
                # the end of the code to be executed when a case option is matched, start of another option
                elsif ( $lctoken eq 'when' && $linestart && $botlevel eq 'case=>' ) {
                    pop @stack;
                    $indent--;
                }

                # endable, indenting keywords which start a syntax line (no label allowed)
                elsif ( $line =~ /^(im)?pure function $/ ) { push @stack, [ $lctoken, $ln ]; $indnext = 1; }
                elsif ( $lctoken =~
                    /^(entity|architecture|configuration|package|function|procedure|component|units)$/
                    && $linestart ) {
                    push @stack, [ $lctoken, $ln ];
                    $indnext = 1;
                }
                # endable, indenting keywords which start a syntax line (label required)
                elsif ( $lctoken =~ /^(block)$/ && $line =~ /^(\S+) : \S+ $/ ) {
                    push @stack, [ $lctoken, $ln, $1 ];
                    $indnext = 1;
                }

                elsif ( $line =~ /^type / && $lctoken =~ /^(access|units|record)$/) {
                    push @stack, [ 'type-'.$lctoken, $ln, $1 ];
                    $indnext = 1;
                    $line    = '';
                }

            }

            if ( $indent < 0 ) { $indent = 0; warn "negative indent, source line $ln" }
            if ( $bracks < 0 ) { $bracks = 0; warn "negative bracket count, source line $ln" }

            if ( $debug & 1 ) {
                # debug dump
                print "# ";
                print "    " x $indent;
                print "  " if $bracks == 0 && !$linestart;
                print $token;
                print " \t\t\tstart=$linestart stack=" . join( ', ', map { $_->[0] . '@' . $_->[1] } @stack );
                print " line='$line'";
                print "\n";
            }
        }

        if ( @outline == 0 ) {
            if ( $type ne 'ws' ) {
                #print "# emitting indent and token '".&escape($token)."'\n";
                if ($type eq 'pp' && !$args{indent_preprocessor}) {
                    # preprocessor command: left-align
                    @outline = ( $token );
                } else {
                    # work out the number of spaces to indent by
                    my $nsp = $indent * $args{indent_spaces};
                    $nsp += $args{cont_spaces} if $bracks == 0 && !$linestart;
                    # create a tab+space sequence to give the correct indent
                    my $ws;
                    if ( $args{tab_spaces} > 0 ) {
                        $ws = ( "\t" x int( $nsp / $args{tab_spaces} ) ) . ( ' ' x ( $nsp % $args{tab_spaces} ) );
                    } else {
                        $ws = ' ' x $nsp;
                    }
                    @outline = ( $ws, $token );
                }
            }
        } else {
            #print "# emitting token '".&escape($token)."'\n";
            push @outline, $token;
        }
        if ( $type =~ /^(wn|pp)$/ ) {
            &$output_func( join( '', @outline ) );
            $ln++;
            @outline = ();
        }

        $indent += $indnext;
        $bracks += $bracknext;
    }
    &$output_func( join( '', @outline ) ) if @outline;
    print "\n" if $debug;
    return;
}

1;

__END__


=head1 NAME

Hardware::Vhdl::Tidy - VHDL code prettifier

=head1 VERSION

This documentation refers to Hardware::Vhdl::Tidy version 0.80.

=head1 SYNOPSIS

Command-line call to make a tidied version of a VHDL file:

    perl -MHardware::Vhdl::Tidy -e "Hardware::Vhdl::Tidy::parse_commandline" < messy.vhd > tidied.vhd
    # or:
    perl -MHardware::Vhdl::Tidy -e "Hardware::Vhdl::Tidy::parse_commandline" messy.vhd > tidied.vhd

Command-line call for an in-place tidy of one or more VHDL files:

    perl -MHardware::Vhdl::Tidy -e "Hardware::Vhdl::Tidy::parse_commandline" -- -b <filenames...>

To tidy a VHDL file from a perl script:

    use Hardware::Vhdl::Tidy qw/ tidy_vhdl_file /;
    tidy_vhdl_file( {
        source => $infile,
        destination => $outfile,
        # the following args are optional, and the values shown are the defaults:
        indent_spaces        => 4, # integer value, >= 0
        cont_spaces          => 2, # integer value, >= 0
        tab_spaces           => 0, # integer value, >= 0
        starting_indentation => 0, # integer value, >= 0
        preprocessor_prefix  => '#', # string
        indent_preprocessor  => 0, # boolean
    } );


To tidy some stored VHDL code in a perl script:

    use Hardware::Vhdl::Tidy qw/ tidy_vhdl /;
    tidy_vhdl( {
        source => $souce_thing, # a scalar, array ref, filehandle ref, object...
        destination => $dest_thing,  # a scalar, array ref, filehandle ref, object...
        # options can be set here, as for tidy_vhdl_file
    } );


=head1 DESCRIPTION

This module auto-indents VHDL source code.  It may be extended in future to
do other types of code prettification.


=head1 SUBROUTINES

=head2 tidy_vhdl

This is the main VHDL-tidying routine.  This
routine takes its arguments in the form of a reference to a hash of named
arguments - the required source and destination arguments, and optional
settings to change the style of the tidying.  These areguments are:

=over 4

=item source

Required argument.  This tells the routine where to get the original VHDL
code from.  This is actually just passed to Hardware::Vhdl::Lexer and can
therefore take the same types of code source:

=over 4

=item tidy_vhdl( { source => $filehandle_reference, ... } );

To read from a file, pass in the filehandle reference like this:

    use Hardware::Vhdl::Tidy qw( tidy_vhdl );
    my $fhi;
    open $fhi, '<', $filename || die $!;
    tidy_vhdl( { source => $fhi, ... } );

If your source and destination data are both in files, see C<tidy_vhdl_file>
for a wrapper function which will open and close the files for you.

=item tidy_vhdl( { source => \@array_of_lines, ... } );

=item tidy_vhdl( { source => \$scalar_containing_vhdl, ... } );

To read VHDL source that is already in program memory, the linesource
argument can be a reference to either an array of lines
or a single string which can have embedded newlines.

=item tidy_vhdl( { source => $object_with_get_next_line_method, ... } );

The linesource argument can be an object with a C<get_next_line> method.
This method must return undef when there are no more lines to read.

=item tidy_vhdl( { source => \&subroutine_that_returns_lines, ... } );

If none of the above input methods suits your needs, you can give a subroutine reference and wrap whatever code you
need to get the VHDL source.  When called, this subroutine must return each line of source code in turn, and then return
undef when there are no more lines.

=back

=item destination

Required argument.  The tidy_code routine generates tidied code output
line by line, and outputs each line seperately using the 'destination'
argument.  The types of thing that you can pass as the destination argument
are:

=over 4

=item tidy_vhdl( { destination => $filehandle_reference, ... } );

    use Hardware::Vhdl::Tidy qw( tidy_vhdl );
    my $fho;
    open $fho, '>', $output_filename || die $!;
    tidy_vhdl( { source => $fho, ... } );

=item tidy_vhdl( { destination => \@array_of_lines, ... } );

You can pass an array reference as the destination parameter, in which case
each line of tidied VHDL code is appended as a new element at the end of the
referenced array.

=item tidy_vhdl( { destination => \$scalar_containing_vhdl, ... } );

You can pass an scalar reference as the destination parameter, in which case
each line of tidied VHDL code is appended to the referenced string.

=item tidy_vhdl( { destination => \&subroutine_that_accepts_lines, ... } );

You can pass an subroutine reference as the destination parameter, in which
case the subroutine is called for each line of tidied VHDL code, with the
line of code as the subroutine parameter.

=back

=item indent_spaces

This optional argument sets the number of columns per indentation level
(default is 4).

=item cont_spaces

This optional argument sets the number of extra indentation spaces applied
when a long line is broken.  The default is 2, as illustrated below:

    process
    begin
        wait on foo;
        t <= al
          -foo*5;
        q <= t
          + bar
          * x;
    end
      process
      ;

=item tab_spaces

This setting causes the specified number of initial space characters to be
replaced by one tab character.  Note that this setting is completely
independent of the value specified for the indent_spaces parameter.
The default value of this setting is 0, which means that tab characters
are not used for indentation.

=item starting_indentation

If you are tidying a section of VHDL code, rather than a complete VHDL file,
you may want to have the whole tidied section indented to the right by some
amount.  This parameter adds a specified number of indentation levels (not
character columns) to all the tidied output.

=item preprocessor_prefix

Some people like to use a preprocessor as part of their design entry
system.  Preprocessor directives need to be ignored by the (partial) parser
that this module includes to work out indentation.  By default, if a line
starts with a '#' character (optionally preceded by some whitespace) then
the line is taken to be a preprocessor directive, and is ignored by the
parser.  You can change the preprocessor directive indicator to a different
string by passing it in as the 'preprocessor_prefix' argument.
The way this is implemented at the moment means that the prefixes that will
work are somewhat limited, but '#' and '@' are known to be OK.  If you
want something else, try it - if it doesn't work, let me know.

=item indent_preprocessor

By default, preprocessor directives are left-aligned.  By setting this
argument to a true value, you can request Hardware::Vhdl::Tidy to give
them the same indentation as the previous line.

=back


=head2 tidy_vhdl_file

This function acts as a wrapper for C<tidy_vhdl> for command-line usage,
converting command-line switches and filenames into function parameters and
dealing with in-place file handling.

The parameter list is the same as for C<tidy_vhdl>, except that 'source'
and 'destination' are filenames and are optional.  If 'source' is not
defined then STDIN is read, and if 'destination' is not defined then
STDOUT is written to.

=head2 parse_commandline

This function is provided so that the module can be called from the command
line.  It scans @ARGV for switches and filenames and then calls
C<tidy_vhdl_file>.  The tidied output is either sent to STDOUT or is used
to replace the original file.  Multiple files may be named in @ARGV: these
are all taken to be input for tidying.

The recognised switches are:

=over 4

=item -b

If this switch is present in @ARGV and a filename is also present, then the
file is tidied in-place.  To do this, the original file is renamed with an
extension of '.bak', and then the tidied output is written to the original
filename.

=item --bext <string>

You can use this switch to provide an alternative extension to add to the
end of the input filename(s) to make the backup filename(s).  The default
is '.bak'.

=item --indentation <n>

=item -i <n>

This switch sets the 'indent_spaces' parameter internally:
this sets the number of columns per indentation level
(default is 4).

=item --continuation-indentation <n>

=item -ci <n>

This switch sets the 'cont_spaces' parameter internally:
this sets the number of extra indentation spaces applied
when a long line is broken.  The default is 2.

=item -t <n>

=item --tab_spaces <n>

This switch sets the 'tab_spaces' parameter internally:
this sets the number of initial spaces to be replaced by a tab character.  
The default is 0, meaning tab characters will not be used for indentation.

=item --sil <n>

=item --starting-indentation-level <n>

This switch sets the 'starting_indentation' parameter internally:
this sets the indentation level used at the start of each file.  The default is 0.

=item --ppp <string>

=item --preprocessor-prefix <string>

This switch sets the 'preprocessor_prefix' parameter internally:
this sets the prefix string that identifies preprocessor directive lines.  The default is '#'.

=back

=head1 DIAGNOSTICS

=over 4

=item "tidy_vhdl 'source' parameter is not of a valid type (it is not a reference)"

The linesource parameter needs to be a reference to something.
If your VHDL code to be passed is in a scalar string, you need to pass
in a reference to the string, not the string itself.

=item "tidy_vhdl 'source' parameter is not of a valid type (type is '<type>')"

The linesource parameter that you have passed to new() does not appear to be
a reference to a scalar, a list, a filehandle, a subroutine or an object with
a get_next_line method.  You have passed a reference to something (otherwise
you would see the previous message) and the error message will tell you what
it appears to be a reference to.

=item "Internal error (token failed to match anything)"

This is a "this should never happen" type of error, and is a sign that I have included a bug.
If you ever see this error, or any other error message not documented above,
I would appreciate a bug report describing how to reproduce the error.

=back

=head1 DEPENDENCIES

This module requires the following modules to be available:

=over 4

=item *

Hardware::Vhdl::Lexer: version 1.00 or later

=item *

Carp: any version

=item *

Exporter: any version

=item *

Getopt::Long: any version

=back

=head1 INCOMPATIBILITIES

This module cannot be used with version of Hardware::Vhdl::Lexer before
version 1.00, because the interface to the Lexer module has changed.

=head1 BUGS AND LIMITATIONS

=over 4

=item *

Indenting of preprocessor commands doesn't work correctly with multi-line
preprocessor commands (i.e. where the preprocessor command is made to
continue onto further lines by including a backslash at the end of the line).

=item *

Not all preprocessor_prefix settings will actually work.  Ideally this should
be a regexp, but since the common '#' and '@' prefixes work this is not a
priority to fix at the moment.

=back

Please report any bugs or feature requests to
C<bug-hardware-vhdl-lexer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hardware-Vhdl-Lexer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Patches are welcome.

=head1 AUTHOR

Michael Attenborough, C<< <michael.attenborough at physics.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006 Michael Attenborough (C<< <michael.attenborough at physics.org> >>). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
