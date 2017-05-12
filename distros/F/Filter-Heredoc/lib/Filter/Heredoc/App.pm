package Filter::Heredoc::App;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

Filter::Heredoc::App - The module behind the filter-heredoc command

=head1 VERSION

Version 0.02

=cut

use base qw( Exporter );
our @EXPORT_OK = qw ( run_filter_heredoc );

use Filter::Heredoc qw( hd_getstate hd_init hd_labels );
use Filter::Heredoc::Rule qw( hd_syntax );
use File::Basename qw( basename );
use POSIX qw( strftime );
use Getopt::Long;
use Carp;

our $SCRIPT = basename($0);

our @gl_delimiterarray          = ();    # delimiters to match
our @gl_to_be_unique_delimiters = ();    # (to be) unique delimiters
our $gl_is_successful_match     = 0;     # successful match flag

### Export_ok subroutines starts here ###

### INTERFACE SUBROUTINE ###
# Usage      : run_filter_heredoc()
# Purpose    : This module implements the logic and functions to
#              search and filter here documents in scripts.
#              This is the code behind the filter-heredoc command.
# Return     : Normally returns to caller or dies with exit code 0.
# Errors     : Dies with exit code 1 on user errors. Dies with exit
#              code 2 on internal errors in hd_getstate().
# Throws     : No.

sub run_filter_heredoc {

    my $linestate;
    my %state;
    my $EMPTY_STR        = q{};
    my $PROMPT           = q{> };
    my $POD              = q{pod};
    my $is_interactive   = ( ( -t STDIN ) && ( -t STDOUT ) );
    my $is_use_prompt    = $EMPTY_STR;
    my $is_with_fileinfo = $EMPTY_STR;

    my %user_warning = (
        firstexclusive =>
            q{Options --help(-h), --version(-v) or --rules(-r) can't be specfied at the same time.},
        exclusive =>
            q{Options --list(-l), --list-unique(-u), --debug(-d) or '-' can't be specfied at the same time.},
        delimiters =>
            q{Options --list(-l), --list-unique(-u) or --match(-m) can't be specfied at the same time.},
        filename =>
            q{Missing any file arguments. Type --help for information.},
        notextfile =>
            q{Please try again, and limit the files to readable text files.},
    );

    # Flush all state arays and activate syntax rule 'pod' as default
    hd_init();
    hd_syntax($POD);

    # Configure long options handling
    Getopt::Long::Configure("no_auto_abbrev")
        ;    # must spell out full long option
    Getopt::Long::Configure("bundling");          # bundle the short options
    Getopt::Long::Configure("no_ignore_case");    # use correct case

    ##############################################################
    # Do some internal checks before @ARGV is shifted by Getopt
    ##############################################################

    # Have we the mandatory filename argument on the command line. In
    # a pipe or redirect, @ARGV is empty, therefore '$is_interactive'.
    if ( ($is_interactive) && ( $#ARGV == -1 ) ) {
        _print_to_stderr_exit( \$user_warning{filename} );
    }

    # Test and prepare possible for line-by-line interactive mode.
    $is_use_prompt = _is_lone_cli_dash(@ARGV);

    ##############################################################
    # Getopt to decode our command line arguments
    ##############################################################

    my ($is_help,  $is_version, $is_quiet, $is_rules,
        $is_debug, $is_list,    $is_unique
    ) = ( 0, 0, 0, 0, 0, 0, 0 );
    my ( $syntax, $match ) = ( $EMPTY_STR, $EMPTY_STR );

    my $options_okay = GetOptions(
        "h|help"        => \$is_help,
        "v|version"     => \$is_version,
        "q|quiet"       => \$is_quiet,
        "d|debug"       => \$is_debug,
        "i|interactive" => \$is_use_prompt,
        "r|rules"       => \$is_rules,
        "l|list"        => \$is_list,
        "u|list-unique" => \$is_unique,
        "s|syntax=s"    => \$syntax,
        "m|match=s"     => \$match,
    );

    ##############################################################
    # Getopt done.
    ##############################################################

    _help() if !$options_okay;

    ########################################
    # Exclusive do-and-exit-options: --version, --help, and --rules
    my $useroptions = 0;
    foreach ( $is_help, $is_version, $is_rules ) {
        $useroptions++ if $_;
    }
    _print_to_stderr_exit( \$user_warning{firstexclusive} )
        if ( $useroptions > 1 );

    ########################################
    # Execute the do-and-exit options first
    if ($is_help) {
        _print_help();
    }
    elsif ($is_version) {
        _print_version();
    }
    elsif ($is_rules) {
        _print_rules();
    }

    ########################################
    # Populate the global array of target delimiters to match
    if ($match) {
        _set_match_delimiters($match);
    }
    ########################################
    # Exclusive options tests
    # Test --list, --list-unique, --debug and '-'
    $useroptions = 0;
    foreach ( $is_list, $is_debug, $is_use_prompt, $is_unique ) {
        $useroptions++ if $_;
    }
    _print_to_stderr_exit( \$user_warning{exclusive} ) if ( $useroptions > 1 );

    # --list or --list-unique (prints all delimiters)
    # and --match (use specific delimiter) is mutually exclusive.
    if ( $is_list || $is_unique ) {

        # Array contains elements, e.g. '--match=eof,eot' is given
        if ( ( $#gl_delimiterarray >= 0 ) && ($match) ) {
            _print_to_stderr_exit( \$user_warning{delimiters} );
        }
    }

    # Should we switch to interactive mode (here line-by-line input)
    if ($is_use_prompt) {
        if ( !$is_interactive ) {
            _help();
        }
        else {
            print "$SCRIPT: Line by line input - use Ctrl-D to quit\n";
            print $PROMPT;
        }
    }

    # Again! Test that we have the mandatory filename arguments
    # Getopt have mangled the @ARGV content after removing options.
    if ( !$is_use_prompt ) {
        _print_to_stderr_exit( \$user_warning{filename} )
            if ( $is_interactive && ( $#ARGV == -1 ) );
    }

    ###########################################################
    # Before we let <> loose, sanitize the file list in @ARGV.
    # Only allow text files, and exit if not.
    ###########################################################

    # Shell have already expanded '*' in @ARGV to file list
    my @files      = @ARGV;
    my @text_files = ();

    if ( ( $#files != -1 ) && ( !_is_lone_cli_dash(@ARGV) ) ) {
        my @no_good_files;
        my $exit_now_flag = 0;

        foreach ( 0 .. $#files ) {

            if ( !-e $files[$_] ) {
                print STDERR
                    "$SCRIPT: cannot access '$files[$_]': Can not access file. Does it exist?\n";
                exit(1);
            }

            # exclude directories
            if ( -d $files[$_] ) {
                next;
            }

            # readable by effective user id, plain file, and text
            elsif ( -r -f -T $files[$_] ) {
                push @text_files, $files[$_];
            }
            else {
                $exit_now_flag = 1;
                push @no_good_files, $files[$_];
            }

        }
        if ($exit_now_flag) {

            if (@text_files) {
                print STDERR "$SCRIPT: These may be acceptable text files:\n";
                foreach my $item (@text_files) {
                    print STDERR "'$item', ";
                }
                print STDERR "\n";
            }
            print STDERR
                "$SCRIPT: These are not plain text files or are not accessible (maybe links):\n";
            foreach my $item (@no_good_files) {
                print STDERR "'$item', ";
            }
            print STDERR "\n$SCRIPT: ";
            my $allstderrprintdone = 1;

            _print_to_stderr_exit( \$user_warning{notextfile} )
                if ($allstderrprintdone);

        }    # end exit_now_flag_flag
    }

    # Last time test that we have the mandatory filename arguments after
    # that we mangled the file list @text_files content.
    if ( !$is_use_prompt ) {
        _print_to_stderr_exit( \$user_warning{filename} )
            if ( $is_interactive && ( $#text_files == -1 ) );
    }

    ###########################################################
    # Set our syntax if given any
    if ($syntax) {
        _set_syntax_rules($syntax);
    }

    ###########################################################
    # Main loop processing one line after line from STDIN
    ###########################################################
    while ( defined( my $line = <ARGV> ) ) {

        # print all here-doc delimiters (i.e. '--list' or '--list-unique')
        if ( ( $is_list || $is_unique ) && ( !$is_use_prompt ) ) {

            if ( !$is_quiet ) {
                $is_with_fileinfo = 1;    # adds file information
            }
            _print_all_delimiters( $line, $is_with_fileinfo, $is_unique );

        }

        # end --list, --list-unique options (print all here-doc delimiters)

        elsif ( !$is_use_prompt ) {

            ### print here-doc content (default without any options)
            my $is_add_label;
            if ( !$is_quiet ) {
                $is_with_fileinfo = 1;    # file information when printing
            }

            # print all lines for debug incl state code (i.e. --debug option)
            if ($is_debug) {
                $is_add_label = 1;
                _debug_every_line( $line, $is_with_fileinfo, $is_add_label );
            }

            # print only the embedded here document lines (default option)
            else {
                $is_add_label = $EMPTY_STR;
                _print_heredoc( $line, $is_with_fileinfo, $is_add_label );
            }
            ### end print here-doc content

        }

        # Inter-active and no cmd line arguments.
        if ($is_use_prompt) {

            ############## If exception exit(2) ########
            eval { %state = hd_getstate($line); };
            if ($@) {
                my $logcreated = _write_error_file( $@, _get_error_fname() );
                if ($logcreated) {
                    print STDERR "Fatal internal errors, see file:",
                        _get_error_fname(), "\n";
                }
                exit(2);
            }
            ############################################
            print "$state{statemarker}]$line";

            print $PROMPT;    # We can test the script with Test::Expect
        }
        elsif (eof) {

            # --list-unique
            if ($is_unique) {
                if ($is_quiet) {
                    _print_unique_delimiters($EMPTY_STR);
                }
                else {
                    _print_unique_delimiters($ARGV);    # current file name
                }
                print "\n";    # new line after each file
            }

            # --match
            if ($match) {
                if ( !$gl_is_successful_match ) {
                    print "($ARGV)" unless ($is_quiet);
                    print
                        "Sorry, no here document content matched your delimiter(s): '$match'. Try --list.\n";
                }

                $gl_is_successful_match = $EMPTY_STR;    # False
            }


            close(ARGV);
            hd_init()
                ;    # re-init state explicitely to flush state possible errors
        }

        # end inter-active and no cmd line arguments

    }

    print "\n";      # print one LF before returning to caller script and exit.
    return;

}

### The Module private subroutines starts here ###

### INTERNAL UTILITY ###
# Usage     : _print_help()
# Purpose   : Print command line help
# Returns   : No, dies with exit code 0
# Throws    : No

sub _print_help {

    print <<"END_USAGE";
    
  $SCRIPT: Filter embedded here-documents in scripts
    
  Usage:

  $SCRIPT [options] file
  $SCRIPT [options] < file
  cat file | $SCRIPT [options] | program

  file: Source script file with embedded here-documents
  program: Program to receive input from $SCRIPT output

  Options

  --list,-l               : list all delimiters and exit.
  --list-unique,-u        : list only unique delimiters and exit. 
  --match=,-m <delimiter> : print only here-documents matching the delimiters. 
  --quiet,-q              : supress file information.

  --rules,-r              : list available rules and exit.
  --syntax=,-s <rule>     : add specified rule(s).  
  
  --help,-h               : show this help and exit.  
  --version,-v            : print $SCRIPT version information and exit.
  --debug,-d              : print all script lines, not only here-document lines.
  --interactive,-i|-      : enter text line-by-line (for state debugging).
  
  Type 'perldoc $SCRIPT' for more information.  
    
END_USAGE

    exit(0);

}

### INTERNAL UTILITY ###
# Usage     : _print_version()
# Purpose   : Print version, copyright and disclaimer
# Returns   : No, dies with exit code 0
# Throws    : No

sub _print_version {

    print <<"END_VERSION";
    
 $SCRIPT, version $VERSION
 Copyright 2011, Bertil Kronlund
 
 This program is free software; you can redistribute it and/or modify it
 under the terms of either: the GNU General Public License as published
 by the Free Software Foundation; or the Artistic License.

 See http://dev.perl.org/licenses/ for more information.
 
 THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

END_VERSION

    exit(0);

}

### INTERNAL UTILITY ###
# Usage     : _print_rules()
# Purpose   : print the available syntax rules
# Returns   : No, dies with exit code 0
# Throws    : No

sub _print_rules {
    my $EMPTY_STR = q{};
    my $value     = shift;
    my %syntax;

    if ( !defined $value ) {

        # Request rule capabilities
        %syntax = hd_syntax();

        print "Available options to use with --syntax option: ";
        foreach ( keys %syntax ) {
            print "'$_' ";
            if ( $syntax{$_} ne $EMPTY_STR ) {
                print '(active) ';
            }
        }

        print "\n";
        exit(0);
    }

}

### INTERNAL UTILITY ###
# Usage     : _set_syntax_rules()
# Purpose   : Sets the syntax rule during this run.
# Returns   : Normally returns to caller or dies
#             with exit code 1 on user error.
# Throws    : No

sub _set_syntax_rules {
    my $EMPTY_STR = q{};
    my $NONE      = q{none};
    my $rule      = shift;
    my %syntax;

    if ( $rule =~ m/^-/xsm ) {
        print "Invalid --syntax argument option: '$rule'\n";
        exit(1);
    }
    else {

        # Try to set given rule
        $rule   = lc($rule);          # Ignore case
        %syntax = hd_syntax($rule);

        # if rule is word 'none' (i.e flush all rules) we are done
        if ( $rule ne $NONE ) {

            # Was this a non-existent key?
            if ( !exists $syntax{$rule} ) {
                print "Invalid syntax rule option: '$rule'. ",
                    "Try option --rules to view all available.\n";
                exit(1);
            }

            # Was the change applied
            elsif ( $syntax{$rule} eq $EMPTY_STR ) {
                print "Sorry, could not add new rule: '$rule'. ",
                    "Try option --rules to view all available.\n";
                exit(1);
            }
        }

    }
    return;
}

### INTERNAL UTILITY ###
# Usage     : _set_match_delimiters ( $delimiters )
# Purpose   : Populate the global delimiters array with
#             the delimiters to match. (option --match)
# Returns   : Normally returns to caller or dies
#             with exit code 1 on user error.
# Throws    : No

sub _set_match_delimiters {
    my $EMPTY_STR = q{};
    my $value     = shift;

    if ( $value eq $EMPTY_STR ) {
        print "No matching delimiter specified!\n";
        exit(1);
    }
    elsif ( $value =~ m/^-/xsm ) {
        print "Invalid --match argument option: '$value'\n";
        exit(1);
    }

    # $value contains a comma separated string of delimiters
    chomp $value;

    # Assign our global array with the delimiters
    @gl_delimiterarray = split( ',', $value );

    return;

}

### INTERNAL UTILITY ###
# Usage     : _print_to_stderr_exit()
# Purpose   : Print user errors and die.
# Returns   : No, dies with exit code 1
# Throws    : No

sub _print_to_stderr_exit {

    my $href_errmsg = shift;
    print STDERR "$$href_errmsg \n";
    exit(1);

}

### INTERNAL UTILITY ###
# Usage     : _is_lone_cli_dash()
# Purpose   : Test if @ARGV contains the lone dash ('-').
# Returns   : True (1) if found, otherwise $EMPTY_STR
# Throws    : No

sub _is_lone_cli_dash {

    my @cmdlinearray = @ARGV;
    my $EMPTY_STR    = q{};

    my $regex = qr/(\s*-\s*)/;    # try to match '-'

    foreach ( 0 .. $#cmdlinearray ) {

        if ( $cmdlinearray[$_] =~ $regex ) {

            # Nothing before and after
            if ( ( $` eq $EMPTY_STR ) && ( $' eq $EMPTY_STR ) ) {

                # Found the lone dash
                return 1;
            }
        }
    }

    return $EMPTY_STR;
}

### INTERNAL UTILITY ###
# Usage     : _print_all_delimiters( $line, IS_FILEINFO, IS_UNIQUE )
# Purpose   : Print the delimiters only. Handles options
#             --list and --list-unique. The 2nd argument
#             '$is_with_fileinfo' only apply to --list.
# Returns   : N/A. Normally returns to caller.
# Errors    : Dies with exit code 2, internal errors in hd_getstate().
# Throws    : No

sub _print_all_delimiters {

    my ( $line, $is_with_fileinfo, $is_unique_list ) = @_;
    my $EMPTY_STR = q{};
    my %state;

    # Read out the default state label symbols
    my %label = hd_labels();

    ############## If exception exit(2) ########
    eval { %state = hd_getstate($line); };
    if ($@) {
        my $logcreated = _write_error_file( $@, _get_error_fname() );
        if ($logcreated) {
            print STDERR "Fatal internal errors, see file:",
                _get_error_fname(), "\n";
        }
        exit(2);
    }
    ############################################

    if ( $state{blockdelimiter} ne $EMPTY_STR ) {

        # The delimiter is the terminator on the egress line ('E')
        if ( $state{statemarker} eq $label{egress} ) {

            # Option --list-unique
            if ($is_unique_list) {

                # Add all, will become unique in _print_unique_delimiters()
                push @gl_to_be_unique_delimiters, $state{blockdelimiter};
            }

            # Option --list
            else {

                # File information not available is pipe or redirect
                if ( $ARGV =~ m/^-/xsm ) {
                    $is_with_fileinfo = $EMPTY_STR;
                }

                # Print the delimiter itself (stored in 'blockdelimiter')
                if ($is_with_fileinfo) {
                    print "($ARGV:$.)$state{blockdelimiter} \n";
                }
                else {
                    print "$state{blockdelimiter} \n";
                }
            }

        }    # end the last delimiter (at egress)

    }    # end delimiter found in block

    return;
}

### INTERNAL UTILITY ###
# Usage     : _debug_every_line( $line, IS_FILEINFO, IS_ADDLABEL )
# Purpose   : Print every line for debugging purpose.
#             Handles option --debug
# Returns   : N/A. Normally returns to caller.
# Errors    : Dies with exit code 2, internal errors in hd_getstate().
# Throws    : No

sub _debug_every_line {

    my ( $line, $is_with_fileinfo, $is_add_label ) = @_;
    my $EMPTY_STR = q{};
    my %state;

    ############## If exception exit(2) ########
    eval { %state = hd_getstate($line); };
    if ($@) {
        my $logcreated = _write_error_file( $@, _get_error_fname() );
        if ($logcreated) {
            print STDERR "Fatal internal errors, see file:",
                _get_error_fname(), "\n";
        }
        exit(2);
    }
    ############################################

    # File information not available is pipe or redirect
    if ( $ARGV =~ m/^-/xsm ) {
        $is_with_fileinfo = $EMPTY_STR;
    }

SWITCH: {
        ( $is_add_label && $is_with_fileinfo ) and do {
            print "($ARGV:$.)$state{statemarker}]$line";
            last SWITCH;
        };
        ( !$is_add_label && $is_with_fileinfo ) and do {
            print "($ARGV:$.)$line";
            last SWITCH;
        };
        ( $is_add_label && !$is_with_fileinfo ) and do {
            print "$state{statemarker}]$line";
            last SWITCH;
        };
        ( !$is_add_label && !$is_with_fileinfo ) and do {
            print "$line";
            last SWITCH;
        };

    };    # switch and combine all variants

    return;
}

####################################################
# Usage: _print_heredoc();
# Purpose: Print (and match lines if set) here document content
# Returns: N/A
# Parameters: line to analyze, and Getopt boolens
# Throws: Yes

sub _print_heredoc {

    my ( $line, $is_with_fileinfo, $is_add_code ) = @_;
    my $EMPTY_STR = q{};

    # Read out the default markers symbols
    my %label = hd_labels();
    my %state;

    ############## If exception exit(2) ########
    eval { %state = hd_getstate($line); };
    if ($@) {
        my $logcreated = _write_error_file( $@, _get_error_fname() );
        if ($logcreated) {
            print STDERR "Fatal internal errors, see file:",
                _get_error_fname(), "\n";
        }
        exit(2);
    }
    ############################################

    if ( $state{statemarker} eq $label{heredoc} ) {

        # File information not available is pipe or redirect
        if ( $ARGV =~ m/^-/xsm ) {
            $is_with_fileinfo = $EMPTY_STR;
        }

        # Print only here document matching the set delimiters
        if (@gl_delimiterarray) {

            foreach my $lineitem (@gl_delimiterarray) {

                if ( $state{blockdelimiter} eq $lineitem ) {

                    $gl_is_successful_match = 1;    # True

                SWITCH: {
                        ( $is_add_code && $is_with_fileinfo ) and do {
                            print "($ARGV:$.)$state{statemarker}]$line";
                            last SWITCH;
                        };
                        ( !$is_add_code && $is_with_fileinfo ) and do {
                            print "($ARGV:$.)$line";
                            last SWITCH;
                        };
                        ( $is_add_code && !$is_with_fileinfo ) and do {
                            print "$state{statemarker}]$line";
                            last SWITCH;
                        };
                        ( !$is_add_code && !$is_with_fileinfo ) and do {
                            print "$line";
                            last SWITCH;
                        };

                    };    # switch and combine all variants

                }    # if match blockdelimiter and item

            }    # end foreach

        }

        # Print every line (option --match not used)
        else {

        SWITCH: {
                ( $is_add_code && $is_with_fileinfo ) and do {
                    print "($ARGV:$.)$state{statemarker}]$line";
                    last SWITCH;
                };
                ( !$is_add_code && $is_with_fileinfo ) and do {
                    print "($ARGV:$.)$line";
                    last SWITCH;
                };
                ( $is_add_code && !$is_with_fileinfo ) and do {
                    print "$state{statemarker}]$line";
                    last SWITCH;
                };
                ( !$is_add_code && !$is_with_fileinfo ) and do {
                    print "$line";
                    last SWITCH;
                };
            };    # switch and combine all variants
        }

    }    # end here document

    return;
}

### INTERNAL UTILITY ###
# Usage     : _is_cli_with_other_than_option()
# Purpose   : Test if @ARGV contains any other arguments than
#             than the lonely dash '-'
# Returns   : True (1) if found, otherwise $EMPTY_STR
# Throws    : No

sub _is_cli_with_other_than_option {

    my $EMPTY_STR    = q{};
    my @cmdlinearray = @ARGV;

LOOP:
    foreach ( 0 .. $#cmdlinearray ) {

        if ( $cmdlinearray[$_] =~ m/(-[a-zA-Z])+/ ) {
            next LOOP;
        }
        else {
            return 1;    # True, found something trailing the '-'
        }
    }

    return $EMPTY_STR;    # False, only '-' (or empty @ARGV)
}

### INTERNAL UTILITY ###
# Usage     : _print_unique_delimiters()
# Purpose   : Print only the unique delimiters.
# Returns   : Normally returns to caller.
# Throws    : No

sub _print_unique_delimiters {
    my $EMPTY_STR = q{};
    my $file      = shift;
    my %seen;

    # Test for option --quiet (i.e. $file is set to $EMPTY_STR)
    if ( $file ne $EMPTY_STR ) {
        print "($file)";
    }

    # Make unique delimiter list from global array of found delimiters
    my @unique = grep { !$seen{$_}++ } @gl_to_be_unique_delimiters;

    # print the unique list
    foreach my $item (@unique) {
        print "$item ";
    }

    @gl_to_be_unique_delimiters = ();

    return;
}

### INTERNAL UTILITY ###
# Usage     : _write_error_file( $@, $err_filename )
# Purpose   : Writes the error message to file in user home directory.
# Returns   : True if file open ok, false otherwise.
# Throws    : No

sub _write_error_file {
    my ( $err_str, $log_fname ) = @_;
    my $EMPTY_STR = q{};
    my $log_fh;

    open $log_fh, '>>', $log_fname
        or return $EMPTY_STR;

    print $log_fh "$err_str\n";
    close($log_fh);
    return 1;
}

### INTERNAL UTILITY ###
# Usage     : _get_error_fname()
# Purpose   : Creates a filename for writing in user home
#             directory with ISO8601 formated date-time stamp.
# Returns   : The name of the error file.
# Throws    : No

sub _get_error_fname {
    my $err_fname = sprintf '%s-%s.error', "$ENV{HOME}/$SCRIPT",
        POSIX::strftime( q!%Y-%m-%d-%H.%M.%SZ!, gmtime );
    return $err_fname;
}

=head1 SYNOPSIS

    use 5.010;
    use Filter::Heredoc::App qw( run_filter_heredoc );
    run_filter_heredoc();
  
=head1 DESCRIPTION

This module implements the logic and functions to search and filter
here documents in scripts. Support for shell script is more mature than
other near compatible languages like Perl. Don't rely on current
version code for Perl since it's still in an early development.

=head1 SUBROUTINES

I<Filter::Heredoc::App> exports following subroutine only on request.

    run_filter_heredoc   # runs the filter-heredoc application code
        
=head2 B<run_filter_heredoc>

    run_filter_heredoc();
    
This function is called by I<filter-heredoc> and implements the
logic and functions to search and filter here documents from the
command line.

=head1 ERRORS

On user errors dies with exit(1). Exceptions for C<hd_getstate> are
trapped and after writing an error file, dies with exit code 2.
    
=head1 BUGS AND LIMITATIONS

I<Filter::Heredoc::App> understands here documents syntax in *nix
shells scripts. Running other script languages will result in an
unpredictable output. This is not regarded as a bug.

Please report any bugs or feature requests to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filter-Heredoc> or at
C<< <bug-filter-heredoc at rt.cpan.org> >>.

=head1 AUTHOR

Bertil Kronlund, C<< <bkron at cpan.org> >>

=head1 SEE ALSO

L<Filter::Heredoc>, L<filter-heredoc>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-12, Bertil Kronlund

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Filter::Heredoc::App
