package EOL;

# | PACKAGE | EOL
# | AUTHOR  | Todd Wylie
# | EMAIL   | perldev@monkeybytes.org
# | ID      | $Id: EOL.pm 238 2006-10-31 19:08:15Z twylie $

# ---------------------------------------------------------------------------
# PURPOSE:
# This module aids in the conversion of text file newline characters within
# the context of other perl code. There are several choices a user can
# specifiy; see POD for details on usage.
# ---------------------------------------------------------------------------

use version; $VERSION = qv('0.0.2');
use warnings;
use strict;
use Carp;

# END OF LINE DECLARATIONS
my $CR   = "\015";      # Apple II family, Mac OS thru version 9
my $CRLF = "\015\012";  # CP/M, MP/M, DOS, Microsoft Windows
my $LF   = "\012";      # Unix, Linux, Xenix, Mac OS X, BeOS, Amiga
my $FF   = "\014";      # printer form feed

# --------------------------------------------------------------------------
# E O L  N E W  F I L E  (subroutine)
# ==========================================================================
# USAGE      : eol_new_file( in => $in_fh, out => $out_fh, eol => 'LF' );
# PURPOSE    : Incoming file's newlines converted & saved to new file.
# RETURNS    : none
# PARAMETERS : in  => '' # file handle
#            : out => '' # file handle
#            : eol => '' # [CR; CRLF; LF]
# THROWS     : Croaks if required arguments missing/null or unknown.
# COMMENTS   : By default, all newlines will be converted to standard
#            : Unix-style line feeds (LF or octal \012). A user may change
#            : the end-of-file tag manually by supplying the "eol" argument.
#            : Acceptable eol tags are: CR; CRLF; LF.
# SEE ALSO   : n/a
# --------------------------------------------------------------------------
sub eol_new_file {
    my %args = @_;
    my $EOL;

    # Check arguments:
    foreach my $arg (keys %args) {
        if ( ($arg ne "in") && ($arg ne "out") && ($arg ne "eol") ) {
            croak "EOL reports: not legal arg \"$arg\".";
        }
    }

    # Check for text file input:
    if (!-T $args{in}) {
        croak "EOL reports: $args{in} is not a text file.";
    }

    # Conversion steps:
    open(IN, "$args{in}") or croak "EOL reports: cannot open $args{in}.";
    if (-f $args{out}) { unlink($args{out}) }
    open(OUT, ">$args{out}") or croak "EOL reports: cannot open $args{in}.";
    if ($args{eol}) {
        ($args{eol} eq "CR")     ? ($EOL = $CR  )
        : ($args{eol} eq "CRLF") ? ($EOL = $CRLF)
        : ($args{eol} eq "LF"  ) ? ($EOL = $LF  )
        : croak "EOL reports: not legal EOL tag! Use only: CR; CRLF; LF.";
    }
    else {
        $EOL = $LF;  # Default is Unix line feed.
    }
    while(<IN>) {
        s/$CRLF$|$CR|$FF$|$LF$/$EOL/g;
        print OUT $_;
    }
    close(IN);
    close(OUT);

    return(1);
}

# --------------------------------------------------------------------------
# E O L  S A M E  F I L E  (subroutine)
# ==========================================================================
# USAGE      : eol_same_file( in => $in_fh, eol => 'LF', backup => '.bak' );
# PURPOSE    : Incoming file's newlines converted & overwrites self.
# RETURNS    : none
# PARAMETERS : in     => '' # file handle
#            : eol    => '' # [CR; CRLF; LF]
#            : backup => '' # scalar
# THROWS     : Croaks if required arguments missing/null or unknown.
# COMMENTS   : By default, all newlines will be converted to standard
#            : Unix-style line feeds (LF or octal \012). A user may change
#            : the end-of-file tag manually by supplying the "eol" argument.
#            : Acceptable eol tags are: CR; CRLF; LF. As already mentioned,
#            : this routine will clobber the in-file. Sending the "backup"
#            : argument with a file suffix will produce a one-time backup of
#            : the original file. !!! USE AT OWN RISK !!!
# SEE ALSO   : n/a
# --------------------------------------------------------------------------
sub eol_same_file {
    my %args = @_;
    my $EOL;

    # Check arguments:
    foreach my $arg (keys %args) {
        if ( ($arg ne "in") && ($arg ne "backup") && ($arg ne "eol") ) {
            croak "EOL reports: not legal arg \"$arg\".";
        }
    }

    # Check for text file input:
    if (!-T $args{in}) {
        croak "EOL reports: $args{in} is not a text file.";
    }

    # Conversion steps:
    if ($args{eol}) {
        ($args{eol} eq "CR")     ? ($EOL = $CR  )
        : ($args{eol} eq "CRLF") ? ($EOL = $CRLF)
        : ($args{eol} eq "LF"  ) ? ($EOL = $LF  )
        : croak "EOL reports: Not legal EOL tag! Use only: CR; CRLF; LF.";
    }
    else {
        $EOL = $LF;  # Default is Unix line feed.
    }
    (exists $args{backup}) ? ($^I = $args{backup}) : ($^I = "");
    while(<>) {
        s/$CRLF$|$CR|$FF$|$LF$/$EOL/g;
        print $_;
    }

    return(1);
}

# --------------------------------------------------------------------------
# E O L  R E T U R N  A R R A Y  (subroutine)
# ==========================================================================
# USAGE      : eol_return_array( in => $in_fh, eol => 'LF' );
# PURPOSE    : Incoming file's newlines converted & array of lines returned.
# RETURNS    : array-reference
# PARAMETERS : in     => '' # file handle
#            : eol    => '' # [CR; CRLF; LF]
# THROWS     : Croaks if required arguments missing/null or unknown.
# COMMENTS   : By default, all newlines will be converted to standard
#            : Unix-style line feeds (LF or octal \012). A user may change
#            : the end-of-file tag manually by supplying the "eol" argument.
#            : Acceptable eol tags are: CR; CRLF; LF. An array reference to
#            : the converted file lines will be returned. Obviously, for
#            : larger files, this may be a considerable drain on memory.
# SEE ALSO   : n/a
# --------------------------------------------------------------------------
sub eol_return_array {
    my %args = @_;
    my $EOL;

    # Check arguments:
    foreach my $arg (keys %args) {
        if ( ($arg ne "in") && ($arg ne "eol") ) {
            croak "EOL reports: not legal arg \"$arg\".";
        }
    }

    # Check for text file input:
    if (!-T $args{in}) {
        croak "EOL reports: $args{in} is not a text file.";
    }

    # Conversion steps:
    my @lines;
    open(IN, "$args{in}") or croak "EOL reports: cannot open $args{in}";
    if ($args{eol}) {
        ($args{eol} eq "CR")     ? ($EOL = $CR  )
        : ($args{eol} eq "CRLF") ? ($EOL = $CRLF)
        : ($args{eol} eq "LF"  ) ? ($EOL = $LF  )
        : croak "EOL reports: not legal EOL tag! Use only: CR; CRLF; LF.\n\n";
    }
    else {
        $EOL = $LF;  # Default is Unix line feed.
    }
    while(<IN>) {
        my $line = $_;
        $line =~ s/$CRLF$|$CR|$FF$|$LF$/$EOL/g;
        push (@lines, split (/($EOL)/, $line));
    }
    close(IN);

    return(\@lines);
}

1; # End of module.

__END__

# --------------------------------------------------------------------------
# P O D : (area below reserved for documentation)
# ==========================================================================

=head1 NAME

EOL - This module aids in the conversion of text file newline characters within the context of other perl code; includes command line executable.


=head1 VERSION

This document describes EOL version 0.0.2


=head1 SYNOPSIS

    ### EOL NEW FILE (makes Unix)
    use EOL;
    my $in  = "original.txt";
    my $out = "converted.txt";
    EOL::eol_new_file(
                      in  => $in,
                      out => $out,
                      eol => "LF"
                     );

    ### EOL SAME FILE (makes older Mac)
    use EOL;
    my ($in) = $ARGV[0] = "original.txt"; # Must prime @ARGV!
    EOL::eol_same_file(
                       in     => $in,
                       eol    => "CR",
                       backup => ".bak"
                      );

    ### EOL RETURN ARRAY (makes MS-DOS)
    use EOL;
    my $in = "original.txt";
    my $aref = EOL::eol_return_array(
                                     in     => $in,
                                     eol    => "CRLF",
                                    );

Also, see the t/EOL.t test case for examples of implementation. A quick assessment of the converted file can be done by using cat.

 cat -ve <converted file>


=head1 DESCRIPTION

There are several easy, quick command line methods for converting text file line endings, including the venerable:

 perl -i.bak -pe 's/\r\n/\n/' <file>

This module provides routines for newline conversion that may be used in-line within large perl applications. A command line executable which utilizes this module is also included; see:

 perldoc eol


=head1 INTERFACE

The following routines are supported:

=head2 eol_new_file

eol_new_file: A routine to convert line endings and write to a new file. Original file is untouched. This routine takes two incoming arguments which correspond to input and output file names. By default, all newlines will be converted to standard Unix-style line feeds (LF or octal \012). A user may change the end-of-file tag manually by supplying the "eol" argument. Acceptable eol tags are: CR; CRLF; LF.

 eol_new_file(
              in  => $in,
              out => $out,
              eol => 'LF',
             );

=head2 eol_same_file

eol_same_file: A routine to convert line endings and write to the original file (i.e., clobbers the file you send it). The developer may specify that the original be backed-up a *single* time. This routine takes an incoming argument which corresponds to an input file name. By default, all newlines will be converted to standard Unix-style line feeds (LF or octal \012). A user may change the end-of-file tag manually by supplying the "eol" argument. Acceptable eol tags are: CR; CRLF; LF. As already mentioned, this routine will clobber the in-file. Sending the "backup" argument with a file suffix will produce a one-time backup of the original file. THIS ROUTINE WILL EDIT THE INCOMING FILE IN-PLACE. USE AT OWN RISK.

 my ($in) = $ARGV[0] = "original.txt"; # Must prime @ARGV.
 eol_same_file(
               in     => $in,
               eol    => "CR",
               backup => ".bak"
              );

=head2 eol_return_array

eol_return_array: A routine to convert line endings and return an array reference of all of the converted line. This routine takes one incoming argument which corresponds to an input file name. By default, all newlines will be converted to standard Unix-style line feeds (LF or octal \012). A user may change the end-of-file tag manually by supplying the "eol" argument. Acceptable eol tags are: CR; CRLF; LF. An array reference to the converted file lines will be returned. Obviously, for larger files, this may be a considerable drain on memory.
NOTE: End of line characters are returned as their own fields in the array--that is, they are not tacked on to the proceeding line.

 my $aref = eol_return_array(
                             in  => $in,
                             eol => 'CRLF',
                            );


=head1 DIAGNOSTICS

A user may encounter error messages associated with this module if required method arguments are malformed or missing.

=over

=item C<< EOL reports: not legal arg >>

[An argument was passed that is not legal. See INTERFACE for appropriate arguments per subroutine.]

=item C<< EOL reports: not a text file >>

[A path to a non-plaintext file was passed as input.]

=item C<< EOL reports: cannot open file >>

[There was an error trying to read/or write a file.]

=item C<< EOL reports: not legal EOL tag! Use only: CR; CRLF; LF. >>

[An illegal option was passed to the "eol" option. Legal options are CR; CRLF; LF]

=back


=head1 CONFIGURATION AND ENVIRONMENT

EOL requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module calls a few others: strict; warnings; Carp; version.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-eol@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Todd Wylie

C<< <perldev@monkeybytes.org> >>

L<< http://www.monkeybytes.org >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005, Todd Wylie C<< <perldev@monkeybytes.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perlartistic.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NOTE

This software was written using the latest version of GNU Emacs, the
extensible, real-time text editor. Please see
L<http://www.gnu.org/software/emacs> for more information and download
sources.
