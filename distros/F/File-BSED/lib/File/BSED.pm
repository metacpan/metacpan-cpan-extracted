# $Id: BSED.pm,v 1.15 2007/07/17 15:26:37 ask Exp $
# $Source: /opt/CVS/File-BSED/lib/File/BSED.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.15 $
# $Date: 2007/07/17 15:26:37 $
package File::BSED;
use strict;
use warnings;
use 5.006006;
use Exporter;
use Carp qw(croak);
use vars qw($VERSION @EXPORT_OK @ISA);

$VERSION   = 0.67;

@EXPORT_OK = qw(
    gbsed
    binary_search_replace
    binary_file_matches
    string_to_hexstring
);

use base qw(Exporter);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub binary_search_replace {
    my ($args_ref) = @_;
    croak 'Argument to File::BSED::binary_search_replace must be hash reference'
        if !ref $args_ref || ref $args_ref ne 'HASH';

    my $search  = $args_ref->{search};
    my $replace = $args_ref->{replace};
    my $infile  = $args_ref->{infile};
    my $outfile = $args_ref->{outfile};

    my $min     = $args_ref->{minmatch} ||  1;
    my $max     = $args_ref->{maxmatch} || -1;


    return _gbsed($search, $replace, $infile, $outfile, $min, $max);
}

sub binary_file_matches {
    my ($search, $infile) = @_;

    return 0 if not $search;

    croak 'Missing filename argument to binary_file_matches()'
        if not defined $infile;

    return _binary_file_matches($search, $infile);
}

sub string_to_hexstring {
    my ($string) = @_;
    return if not $string;

    return _string_to_hexstring($string);
}

sub gbsed {
    goto &binary_search_replace;
}

sub errtostr {
    return _errtostr(_gbsed_errno());
}

sub errno {
    return _gbsed_errno();
}

sub warnings {
    return _warnings();
}

1;

__END__
=pod


=head1 NAME

File::BSED - Search/Replace in Binary Files.

=head1 VERSION

This document describes File::BSED version 0.67

=head1 SYNOPSIS

    use File::BSED qw(binary_search_replace binary_file_matches);

    # search/replace
    my $matches = binary_search_replace({
        search  => 'ff3cea3f0013',
        replace => 'b801000000c3',
        infile  => '/bin/ls',
        outfile => '/tmp/ls.patched'
    });
    if ($matches == -1) {
        my $error_string = File::BSED->errtostr();
        die "Error: $error_string\n";
    }
    print "Replaced $matches time(s)\n";

    # search
    my $matches = binary_file_matches('ff3cea3f0013', '/bin/ls');
    print "Matched $matches time(s)\n";

    # replace 'gnu' to 'bsd'
    my $hex_gnu = File::BSED::string_to_hexstring('gnu');
    my $hex_bsd = File::BSED::string_to_hexstring('bsd');
    my $matches = binary_search_replace({
        search  => $hex_gnu,
        replace => $hex_bsd,
        infile  => '/bin/ls',
        outfile => 'ls.bsd',
    });
    # [...]


=head1 DESCRIPTION

This is a perl-binding to C<libgbsed>, a binary stream editor.

C<gbsed> lets you search and replace binary data in binary files by using hex
values in text strings as search patterns. You can also use wildcard matches
with C<??>, which will match any wide byte.

These are all valid search strings:

    search => "0xffc300193ab2f63a";
    search => "0xff??00??3ab2f??a";
    search => "FF??00??3AB2F??A";

while these are not:

    search => "the quick brown fox"; # only hex, no text. you would have to
                                     # convert the text to hex first.
    search => "0xff?c33ab3?accc";    # no nybbles only wide bytes. (?? not ?).



=head1 SUBROUTINES/METHODS


=head2 CLASS METHODS 

=head3 C<binary_search_replace(\%arguments)>

Search and replace in a binary file.
Valid arguments are:

=over 4

=item search

The pattern to search for. Must be a string with hex digits.

=item replace

What to replace with. Must be a string with hex digits.
(Probably a very good idea that it is the same length as the search pattern).

=item infile

The filename of the file to search in.

=item outfile

The filename of the file to save changes to.

=item minmatch

Need at least C<$minmatch> matches before any work.

=item maxmatch

Stop after C<$maxmatch> matches.

=back

C<bsed> returns the number of times the search string was found
in the file, or C<-1> if an error occurred.
When an error occurs the error number can be found with C<errno>
and you can get a description of the error with C<errtostr>.

Example:

    my $number_of_matches = binary_search_replace({
        search  => '0xff',
        replace => '0x00',
        
        infile  => '/bin/ls',
        outfile => '/bin/ls.patched',
    });

    if ($number_of_matches = -1) {
        die sprintf("ERROR: %s\n", File::BSED->errtostr());
    }
    print "Replaced $number_of_matches time(s).\n";

=head3 C<gbsed(\%arguments)>

Alias to C<binary_search_replace> for backward compatibility.

=head3 C<binary_file_matches($search_pattern, $input_file)>

Return the number of times C<$search_pattern> is found in binary file.
Search pattern must be a string of hex digits.

Example:

    my $number_of_matches = binary_file_matches('0xfeedface', '/bin/ls');
    print "Matched $number_of_matches time(s)\n";

=head3 C<string_to_hexstring($text)>

Convert text to a string of ASCII hex values.

=head2 ERROR HANDLING

=head3 C<errtostr>

This function returns a string describing what happened.
if an error has occurred with either C<binary_search_matches> or C<binary_file_matches>
(they return -1 on error). 

=head3 C<errno>

This function returns the error number if an error has occurred with
either C<binary_search_replace> or C<binary_file_matches> (they return -1 on error). 

Use C<errtostr> instead.

=head2 WARNINGS

=head3 C<warnings()>

Returns an array ref to any warnings raised.

Example:

    my @warnings = @{ File::BSED::warnings() };
    for my $warning (@warnings) {
        warn "Warning: $warning\n";
    }
    
=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

=head1 DEPENDENCIES


=over 4

=item * A working C compiler.

=back


=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-file-bsed@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over 4

=item * L<plbsed>

=back

=head1 AUTHOR

by Ask Solem, C<< ask@0x61736b.net >>.

=head1 ACKNOWLEDGEMENTS

Dave Dykstra C<< dwdbsed@drdykstra.us >>.
for C<bsed> the original program,

I<0xfeedface>
for the wildcards patch.

=head1 LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

=head2 SEE

L<perlartistic> L<perlgpl>

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
