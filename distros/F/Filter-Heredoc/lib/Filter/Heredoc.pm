package Filter::Heredoc;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.05';

=head1 NAME

Filter::Heredoc - Search and filter embedded here documents

=head1 VERSION

Version 0.05

=cut

use base qw(Exporter);
use feature 'state';

use Carp;
use Filter::Heredoc::Rule qw ( _hd_is_rules_ok_line );    # intra sub #

# private subroutines only used in author tests
our @EXPORT_OK = qw (
    hd_init
    hd_getstate
    hd_labels
    _is_comment
    _state
    _strip_quotes
    _infifo
    _is_ingress
    _is_egress
    _strip_tabdelimiter
    _infifotab
    _strip_trailing_pipe
    @CARP_UNDEF
    @CARP_EGRESS
    @CARP_INGRESS
);

# our thrown exceptions. What's wrong, and why it's wrong.
our @CARP_UNDEF = (
    "\nPassed argument to function is undef",
    "\nCan't determine state from an undef argument",
    "\n"
);
our @CARP_EGRESS = (
    "\nCurrent state is Egress, and passed line say we shall change to Egress again",
    "\nNot allowed change i.e. Egress --> Egress",
    "\n"
);
our @CARP_INGRESS = (
    "\nCurrent state is Ingress, and passed line say we shall change to Ingress again",
    "\nNot allowed change i.e. Ingress --> Ingress",
    "\n"
);

### Export_ok subroutines starts here ###

### INTERFACE SUBROUTINE ###
# Usage     : hd_getline ( $line)
# Purpose   : Main routine to determine state changes based on the
#             previous (existing state) and the $line (argument).
# Returns   : Hash with state labels indicating the new state
# Throws    : Yes, see above @CARP-globals

sub hd_getstate {
    my $EMPTY_STR = q{};
    my $line      = shift;
    my %marker    = hd_labels();
    my @parselineitems;
    my $COPYOUTFROMFIFO = 1;

    my %state = (
        statemarker      => $EMPTY_STR,
        blockdelimiter   => $EMPTY_STR,
        is_tabremoveflag => $EMPTY_STR,
    );

    # Argument (the text line) can not be undef
    if ( !defined($line) ) {
        Carp::confess(@CARP_UNDEF);    # trap with eval otherwise die
    }

    chomp $line;

=for StateTests:
    The $line is either the ingress- or egress text line, were the state
    flag needs to toggle, or this is either another full text line of source
    or here document were nothing change if last one was the same.
    The initial state is not important for the start.

=cut

    ###############################################################
    ###  State change tests (source --> source, source -> ingress)
    ###############################################################

    # Test if last state was in 'source'
    if ( _state() eq $marker{source} ) {

        # Test change to 'heredoc' with basic assumption on match for '<<'
        if ( _is_ingress($line) ) {

            # Bugfix DBNX#13
            $line =~ s/\s+$//;    # remove trailing white spaces before split()

            # endfix

            # Each shell ingress text line may contain multiple delimiters
            @parselineitems = split /;/, $line;

            # Process each delimiter (split by ';')
            while ( defined( my $tmpdelim = shift @parselineitems ) ) {

                # Ensure that any parsed sub-lines is not an inline comment
                if ( _is_comment($tmpdelim) ) {
                    next;
                }

              # Bugfix DBNX#11 remove the trailing pipe '|', and any cmd behind
              # it, if present. Applies to 'cat <<eof |'  or cat <<eof | cmd'
                $tmpdelim = _strip_trailing_pipe($tmpdelim);

                # endfix

                # Extract the delimiter under POSIX assumptions
                my $subdelimiter    = $EMPTY_STR;
                my $final_delimiter = $EMPTY_STR;
                $subdelimiter = _get_posix_delimiter($tmpdelim);

                # The saved delimiter can not contain '-' if line was '<<-EOF'
                $final_delimiter = _strip_tabdelimiter($subdelimiter);

                # Set the tab delimiter flag for processing by caller
                if ( $final_delimiter ne $subdelimiter ) {
                    _infifotab(1);    # insert tab removal true flag
                }
                else {
                    _infifotab($EMPTY_STR);    # no tab removal condition
                }

                # Save target 'terminator' to identify egress condition
                _infifo($final_delimiter);
            }

            # Update state
            _state( $marker{ingress} );

            # Only heredoc/egress lines are applicable for tab removal flag
            %state = (
                statemarker      => $marker{ingress},
                is_tabremoveflag => $EMPTY_STR,
                blockdelimiter => $EMPTY_STR,    # ingress is not a here-doc
            );
            return %state;    # Ingress - all delimiters processed on the line

        }    # end if-ingress

        # prepare state hash with no state change from source
        _state( $marker{source} );
        %state = (
            statemarker      => $marker{source},
            is_tabremoveflag => _infifotab( q{}, $COPYOUTFROMFIFO ),
            blockdelimiter   => _infifo( $EMPTY_STR, $COPYOUTFROMFIFO ),
        );
        return %state;    #source

    }    # end if-source

    ###############################################################
    ### State change tests (ingress --> heredoc), and
    ### non valid state change (ingress --> ingress)
    ###############################################################

    # Test if last state was in 'ingress'
    if ( _state() eq $marker{ingress} ) {
        if ( !_is_ingress($line) ) {

            _state( $marker{heredoc} );
            %state = (
                statemarker      => $marker{heredoc},
                blockdelimiter   => _infifo( $EMPTY_STR, $COPYOUTFROMFIFO ),
                is_tabremoveflag => _infifotab( q{}, $COPYOUTFROMFIFO ),
            );
            return %state;    # heredoc

       # Throw an exception with full backtrace, including above error message!
        }
        else {
            Carp::confess(@CARP_INGRESS);    # trap with eval otherwise die
            return;
        }

    }    # end if-ingress

    ###############################################################
    ### State change tests (heredoc --> heredoc, heredoc -> egress)
    ###############################################################

    # Test if last state was in 'heredoc'
    if ( _state() eq $marker{heredoc} ) {

        if ( _is_egress($line) ) {

            # Prepare state hash and change state from heredoc
            _state( $marker{egress} );
            %state = (
                statemarker    => $marker{egress},
                blockdelimiter => _infifo( $EMPTY_STR, $COPYOUTFROMFIFO ),
                is_tabremoveflag => _infifotab(),    # removes the tab flag
            );
            _infifo();    # removes the delimiter from the fifo array

            return %state;    # egress

        }    # end if-egress

        # Prepare state hash with no state change from heredoc
        _state( $marker{heredoc} );
        %state = (
            statemarker      => $marker{heredoc},
            is_tabremoveflag => _infifotab( q{}, $COPYOUTFROMFIFO ),
            blockdelimiter   => _infifo( $EMPTY_STR, $COPYOUTFROMFIFO ),
        );

        return %state;    #heredoc

    }    # end if-heredoc

    ###############################################################
    ### State change tests (egress --> source, egress --> heredoc)
    ### and test for non valid state change (egress --> egress)
    ###############################################################

    # Test if last state was in 'egress'
    if ( _state() eq $marker{egress} ) {

        my $fifolength = length( _infifo( $EMPTY_STR, $COPYOUTFROMFIFO ) );

        # Infifo terminator doesn't contains any delimiters, change to source
        if ( $fifolength == 0 ) {

            _state( $marker{source} );
            %state = (
                statemarker      => $marker{source},
                is_tabremoveflag => $EMPTY_STR,
                blockdelimiter   => _infifo( $EMPTY_STR, $COPYOUTFROMFIFO ),
            );
            return %state;    #source
        }

        if ( ( $fifolength != 0 ) && ( _is_egress($line) ) ) {

            # Unexpected direct egress line again
            Carp::confess(@CARP_EGRESS);    # trap with eval otherwise die
            return;
        }
        else {

            # Terminator array does not match - change state back to heredoc
            _state( $marker{heredoc} );
            %state = (
                statemarker      => $marker{heredoc},
                blockdelimiter   => _infifo( $EMPTY_STR, $COPYOUTFROMFIFO ),
                is_tabremoveflag => _infifotab( q{}, $COPYOUTFROMFIFO ),
            );

            return %state;    #heredoc

        }

    }    # end if-egress

}
### INTERFACE SUBROUTINE ###
# Usage     : hd_labels() or hd_labels( %newlabels )
# Purpose   : Subroutine to get/set state labels.
#             default labels are 'S', 'I', 'H' and 'E'.
#            (i.e Source, Ingress, Heredoc, or Egress)
# Returns   : Hash with the definition of labels for each state
# Throws    : No

sub hd_labels {
    my %arg = @_;
    my %marker;

    $arg{source}  = q{S} unless exists $arg{source};
    $arg{ingress} = q{I} unless exists $arg{ingress};
    $arg{heredoc} = q{H} unless exists $arg{heredoc};
    $arg{egress}  = q{E} unless exists $arg{egress};

    state $source  = $arg{source};
    state $ingress = $arg{ingress};
    state $heredoc = $arg{heredoc};
    state $egress  = $arg{egress};

    return %marker = (
        source  => $source,
        ingress => $ingress,
        heredoc => $heredoc,
        egress  => $egress,
    );
}

### INTERFACE SUBROUTINE ###
# Usage     : hd_init()
# Purpose   : Empties the terminator and tab arrays and set the internal
#             state to source. Used after each file processed in case of
#             the ingress/egress conditions are not found properly.
#             Default labels are 'S', 'I', 'H' and 'E'.
#            (i.e Source, Ingress, Heredoc, or Egress)
# Returns   : $EMPTY_STR
# Throws    : No

sub hd_init {
    my %marker    = hd_labels();        # get default markers
    my $initstate = $marker{source};    # default initial state
    my $EMPTY_STR = q{};

    # Set the state to source
    _state($initstate);

    # Empty the terminator array
FIFOLOOP:
    while ( _infifo() ) {
        next FIFOLOOP;
    }

    # empty the tab array
TABLOOP:
    while ( _infifotab() ) {
        next TABLOOP;
    }

    return $EMPTY_STR;
}


### The Module private subroutines starts here ###

### INTERNAL UTILITY ###
# Usage     : _is_comment( $line )
# Purpose   : Prevent a false ingress condition if line is a comment.
# Returns   : True (1) or False ($EMPTY_STR)
# Throws    : No

sub _is_comment {
    my $EMPTY_STR = q{};
    my $line;

    if ( !defined( $line = shift ) ) {
        return $EMPTY_STR;
    }

    # If only white space left of the '#' its a comment.
    $line =~ tr/ \t\n\r\f//d;

    # Test first character for '#', i.e. index() return 0.
    if ( index( $line, '#' ) == 0 ) {
        return 1;
    }

    return $EMPTY_STR;    # It's not a comment
}

### INTERNAL UTILITY ###
# Usage     : _is_ingress( $line )
# Purpose   : Determine if line is an ingress line (regex /<</)
# Returns   : True (1) or False ($EMPTY_STR)
# Throws    : No

sub _is_ingress {
    my $line      = shift;
    my $EMPTY_STR = q{};

    if ( !_is_comment($line) ) {

        if ( $line =~ m/<</ ) {

            ## Prevent false positives (Filter::Heredoc::Rule) ##
            if ( !_hd_is_rules_ok_line($line) ) {
                return $EMPTY_STR;    # FALSE, not an ingress line
            }

            return 1;                 # TRUE
        }
    }
    return $EMPTY_STR;                # FALSE
}

### INTERNAL UTILITY ###
# Usage     : _is_egress( $line )
# Purpose   : Determine if line is an egress line
# Returns   : True (1) or False ($EMPTY_STR)
# Throws    : No

sub _is_egress {
    my $line             = shift;
    my $EMPTY_STR        = q{};
    my $nextoutdelimiter = $EMPTY_STR;
    my $COPYOUTFROMFIFO  = 1;

=for EgressNotes:
To be a valid delimter, first word in line must match next infifo terminator.
split() defaults to split on ' ' and on $_ (and this is not same as //!)
Currently no rule helper is used on the egress delimiter.
Removes all trailing white space (and if no word, all is removed)

=cut

    $_ = $line;
    my @linefield = split;

    # Check what is waiting (do not remove) from fifo of delimiters
    $nextoutdelimiter = _infifo( $EMPTY_STR, $COPYOUTFROMFIFO );

    # Stop processing, no delimiters in fifo
    if ( $nextoutdelimiter eq $EMPTY_STR ) {
        return $EMPTY_STR;
    }

    # Line is undef for lines with white space
    if ( !defined( $linefield[0] ) ) {
        return $EMPTY_STR;    # FALSE
    }
    elsif ( $nextoutdelimiter eq $linefield[0] ) {
        return 1;             # TRUE
    }

    return $EMPTY_STR;        # FALSE
}

### INTERNAL UTILITY ###
# Usage     : _get_posix_delimiter( $line )
# Purpose   : Extracts the delimiter and assumes POSIX i.e. white
#             space is not significant between '<<' and 'delimiter'.
# Returns   : The delimiter itself (includes '-' if << -EOT).
# Throws    : No

sub _get_posix_delimiter {
    my $tmpdelim     = shift;
    my $EMPTY_STR    = q{};
    my $subdelimiter = $EMPTY_STR;

    # Remove all quote characters and get the delimiter itself
    $tmpdelim =~ s/\s+//g;    # removes all white space (becomes one word)
    $tmpdelim = _strip_quotes($tmpdelim);    # removes any [ " ' \ ]
    $tmpdelim =~ m/<{2}(.*)/;
    $subdelimiter = $1;

    return $subdelimiter;
}

### INTERNAL UTILITY ###
# Usage     : _state() or _state( q{E} )
# Purpose   : Subroutine to get/set the persistent state.
# Returns   : The state (label) of the state machine when called.
# Throws    : No

sub _state {
    my %marker = hd_labels();
    state $linestate = $marker{source};    # default initial state
    my $newstate = shift;

    # Set or get the new state
    $linestate = $newstate if defined $newstate;

    return $linestate;
}

### INTERNAL UTILITY ###
# Usage     : _strip_quotes( $line )
# Purpose   : Before a delimiter is ready to be saved, quotes shall
#             first be removed.
# Returns   : String without any quotes or escapes character i.e. [" ' \ ].
# Throws    : No

sub _strip_quotes {
    my $tmpstr = shift;
    my $noquotesstr;

    $tmpstr =~ tr/\\//d;    # remove all  [\];
    $tmpstr =~ tr/"//d;     # remove all  ["];
    $tmpstr =~ tr/'//d;     # remove all  ['];

    $noquotesstr = $tmpstr;

    return $noquotesstr;
}

### INTERNAL UTILITY ###
# Usage     : _strip_tabdelimiter( $line )
# Purpose   : Removes the tab-delimiter '-' after '<<' if present.
# Returns   : String without '-' or the original string not present.
# Throws    : No

sub _strip_tabdelimiter {
    my $line = shift;

    # Get the string after '-'
    if ( $line =~ m/^-(.*)/ ) {
        return $1;
    }

    return $line;    # ..otherwise return the original string
}

### INTERNAL UTILITY ###
# Usage     : _infifo( $line ), _infifo(), _infifo( $EMPTY_STR, 1 )
# Purpose   : Accessor routine to insert/extract delimiter from fifo array.
#             When extracting, the delimiter is fully removed from array.
#             The last syntax looks for next delimiter without removing it.
# Returns   : Returns the delimiter or an $EMPTY_STR when no delimiters exists.
# Throws    : No

sub _infifo {
    my $EMPTY_STR       = q{};
    my $delimiter       = shift;
    my $copyoutfromfifo = shift || $EMPTY_STR;    # default FALSE
    my $nextelementout;

    # Holds the egress terminator(s) at any given time
    state @terminators;

    # Test that its not the pre-view mode
    if ( !$copyoutfromfifo ) {

        # Insert the new delimiter in the fifo array
        if ( defined $delimiter ) {
            push @terminators, $delimiter;
            return;
        }
        else {

            # Shift out next delimiter
            if ( defined( my $tmp = shift @terminators ) ) {
                return $tmp;
            }
            else {
                return $EMPTY_STR;    # fifo array is empty
            }
        }
    }

    # Neither insert or extract - pre-view next array element in the array
    else {

        # Third mode of syntax, '$copyoutfromfifo' is not-false from above
        if ( $delimiter eq $EMPTY_STR ) {

            # Get one delimiter from the terminator fifo array
            if ( defined( $nextelementout = shift @terminators ) ) {

                # Preserve the fifo array insert the delimiter again
                unshift @terminators, $nextelementout;
                return $nextelementout;
            }
            else {
                return $EMPTY_STR;
            }
        }
    }

}

### INTERNAL UTILITY ###
# Usage     : _infifotab( $flag ), _infifotab(), _infifotab( $EMPTY_STR, 1 )
# Purpose   : Accessor routine to insert/extract true/false from tabfifo array.
#             When extracting, the value is fully removed from array.
#             The last syntax looks for next flag value without removing it.
# Returns   : Returns 1 (true) or an $EMPTY_STR when no flags exists.
# Throws    : No

sub _infifotab {
    my $EMPTY_STR       = q{};
    my $istabremoveflag = shift;   # this is either $EMPTY_STR, or '1' i.e true
    my $copyoutfromfifo = shift || $EMPTY_STR;    # default FALSE
    my $nextelementout;

    # Holds tab-removal flags at any given time
    state @tabremovals;

    # Test that its not the pre-view mode
    if ( !$copyoutfromfifo ) {

        # Add the new flag value to fifo
        if ( defined $istabremoveflag ) {
            push @tabremovals, $istabremoveflag;
            return;
        }
        else {

            # Shift out next flag value
            if ( defined( my $tmp = shift @tabremovals ) ) {
                return $tmp;
            }
            else {
                return $EMPTY_STR;    # fifo array is empty
            }
        }
    }

    # Neither insert or extract - pre-view next array element in the array
    else {

        # Third mode of syntax, '$copyoutfromfifo' is not-false from above
        if ( $istabremoveflag eq $EMPTY_STR ) {

            # Get one tab delimiter from the tabremoval fifo array
            if ( defined( $nextelementout = shift @tabremovals ) ) {

                # Preserve the fifo array insert the flag again
                unshift @tabremovals, $nextelementout;
                return $nextelementout;
            }
            else {
                return $EMPTY_STR;
            }
        }
    }

}

### INTERNAL UTILITY ###
# Usage     : _strip_trailing_pipe( $line )
# Purpose   : Ingress line characters after a pipe (and an optional shell
#             command) must be removed to allow extracting the delimiter.
# Returns   : The line, with everything after the pipe removed incl the pipe
#             or the line untouched if there is no pipe.
# Throws    : No

sub _strip_trailing_pipe {
    my $EMPTY_STR = q{};
    my $line      = shift;
    my $newline   = $EMPTY_STR;

    if ( !defined($line) ) {
        return $EMPTY_STR;
    }

    my $regexpipe    = qr/\|/;
    my $regexcapture = qr/^(.*)\|/;

    # If no pipe return original line
    if ( $line !~ $regexpipe ) {
        return $line;
    }

    # Capture everything up to the pipe symbol
    if ( $line =~ $regexcapture ) {
        $newline = $1;
        return $newline;
    }

    return $line;    # If match fails returns the original string
}


=head1 SYNOPSIS

    use 5.010;
    use Filter::Heredoc qw( hd_getstate hd_init hd_labels );
    use Filter::Heredoc::Rule qw( hd_syntax );
    
    my $line;
    my %state;
    
    # Get the defined labels to compare with the returned state
    my %label = hd_labels();

    # Read a file line-by-line and print only the here document
    while (defined( $line = <DATA> )) {
        %state = hd_getstate( $line ); 
        print $line if ( $state{statemarker} eq $label{heredoc} );
        if ( eof ) {
            close( ARGV ); 
            hd_init(); # Prevent state errors to propagate to next file
        }
    }

    # Test a line (is this an opening delimiter line?)
    $line = q{cat <<END_USAGE};
    %state = hd_getstate( $line ); 
    print "$line\n" if ( $state{statemarker} eq $label{ingress} );
    
    # Load a syntax helper rule (shell script is built in)
    hd_syntax ( 'pod' );

=head1 DESCRIPTION

This is the core module for I<Filter::Heredoc>. If you're not looking
to extend or alter the behavior of this module, you probably want to
look at L<filter-heredoc> instead.

I<Filter::Heredoc> provides subroutines to search and print here
documents. Here documents (also called "here docs") allow a type of
input redirection from some following text. This is often used to embed
short text messages (or configuration files) within shell scripts.

This module extracts here documents from POSIX IEEE Std 1003.1-2008
compliant shell scripts. Perl have derived a similar syntax but is at
the same time different in many details.

Rules can be added to enhance here document extraction, i.e. prevent
"false positives". L<Filter::Heredoc::Rule> exports an additional
subroutine to load and unload rules.

This version supports a basic C<POD> rule. Current subroutines can be
tested on Perl scripts if the code constructs use a near POSIX form
of here documents. With that said don't rely on the current version
for Perl since it's still in a very early phase of development.

=head2 Concept to parse here documents.

This is a line-by-line state machine design. Reading from the beginning
to the end of a script results in following state changes:

    Source --> Here document --> Source
    
What tells a source line from a here document line apart? Nothing!
However if adding an opening and closing delimiter state I<and> tracking
previous state we can identify what is source and what's a here document:

    Source --> Ingress --> Here document --> Egress --> Source

In reality there are few more state changes defined by POSIX.
An example of this is the script below and with added state labels:

    S]   #!/bin/bash --posix
    I]   cat <<eof1; cat <<eof2
    H]   Hi,
    E]   eof1
    H]   Helene.
    E]   eof2
    S]

Naturally, when bash runs this only the here document is printed:

    Hi,
    Helene.

=head1 SUBROUTINES

I<Filter::Heredoc> exports following subroutines only on request.

    hd_getstate   # returns a label based on the argument (text line)
    hd_labels     # reads out and (optionally) define new labels
    hd_init       # flushes the internal state machine
    
L<Filter::Heredoc::Rule> exports one subroutine to load and unload
syntax rules.

    hd_syntax             # load/unload a script syntax rule

=head2 B<hd_getstate>

This routine determines the new state, based on last state C<and> the
new text line in the argument. 

    %state = hd_getstate( $line );
    
Returns a hash with following keys/values:

    statemarker :      Holds a label that represent the state of the line.
    
    blockdelimiter:    Holds the delimiter which belongs to a 'region'.
    
    is_tabremovalflag: If the redirector had a trailing minus this
                       value is true for the actual line.

A here document 'region' is defined as all here document lines being
bracketed by the ingress (opening delimiter) and the egress (terminating
delimiter) line. This region may or may not have a file unique delimiter. 

To prevent unreliable results, only pass a text line as an argument.
Use file test operators if reading input lines from a file:

    if ( -T $file ) {
      print "$file 'looks' like a plain text file to me.\n";
    }

This function throws exceptions on a few fatal internal errors.
These are trappable. See ERRORS below for messages printed.

=head2 B<hd_labels>

Gets or optionally sets a new unique label for the four possible states.

    %label = hd_labels();
    %label = hd_labels( %newlabel );

The hash keys defines the default internal label assignments.

    %label = (
            source  => 'S',
            ingress => 'I',
            heredoc => 'H',
            egress  => 'E',
    );
  
Returns a hash with the current label assignment.

=head2 B<hd_init>

Sets the internal state machine to 'source' and empties all internal
state arrays.

    hd_init();

When reading more that one file, call this function before next file to
prevent any state faults to propagate to next files input. Now
always returns an $EMPTY_STR (q{}) but this may change to indicate an
state error from previous files.


=head1 ERRORS

C<hd_getstate> throws following exceptions.

=over 4

=item * B<undef>

If the text line argument is C<undef> following message, including a
full trace back, is printed.

    Passed argument to function is undef.
    Can't determine state from an undef argument.
    
Ensure that only a plain text line is supplied as an argument.

=item * B<Invalid ingress state change>

If the state machine conclude a change was from Ingress to Ingress
following message, including a full trace back, is printed:

    Current state is Ingress, and passed line say we shall change
    to Ingress again. Not allowed change i.e. Ingress --> Ingress
    
If this happens, please report this as a BUG and how to reproduce.

=item * B<Invalid egress state change>

If the state machine conclude a change was from Egress to Egress
following, including a full trace back, message is printed:

    Current state is Egress, and passed line say we shall change
    to Egress again. Not allowed change i.e. Egress --> Egress.
    
If this happens, please report this as a BUG and how to reproduce.

=back

=head1 DEPENDENCIES

I<Filter::Heredoc> only requires Perl 5.10 (or any later version).

=head1 AUTHOR

Bertil Kronlund, C<< <bkron at cpan.org> >>

=head1 BUGS AND LIMITATIONS

I<Filter::Heredoc> complies with *nix POSIX shells here document syntax.
Non-compliant shells on e.g. MSWin32 platform is not supported.

Please report any bugs or feature requests to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filter-Heredoc> or at
C<< <bug-filter-heredoc at rt.cpan.org> >>.

=head1 SEE ALSO

Overview of here documents and its usage:
L<http://en.wikipedia.org/wiki/Here_document>

The IEEE Std 1003.1-2008 standards can be found here:
L<http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html>

L<Filter::Heredoc::Rule>, L<filter-heredoc>

L<Filter::Heredoc::Cookbook> discuss e.g. how to embed POD as
here documents in shell scripts to carry their own documentation.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-18, Bertil Kronlund

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Filter::Heredoc
