package Hash::MD5;

=pod

=head1 NAME

Hash::MD5 - MD5 checksum for choosen hashref

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

use utf8;
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use vars qw($VERSION @EXPORT_OK);

require Exporter;
*import    = \&Exporter::import;
@EXPORT_OK = qw(sum);

=head1 SYNOPSIS

        use Hash::MD5 qw(sum);
        
        ...
        my $hashref = {some => 'hashref'};
        print sum( $hashref ), $/;
        ...

=head1 SUBROUTINES/METHODS

=head2 sum

=cut

sub sum {
    my ($param) = @_;
    my $arg = ( ref $param ne 'ARRAY' ) ? [$param] : $param;
    return md5_hex( Data::Dumper->new($arg)->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump );
}

1;    # End of Hash::MD5

__END__

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-md5 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-MD5>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-MD5>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-MD5>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-MD5>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-MD5/>

=back


=head1 MOTIVATION

I need a package which I can grab the uniqueness of a Hashrefs in a md5 sum.
This I will compare to later processing.
My first approach was to use encode_json string.
Unfortunately, the resort was not very consistent.

So I wrote my first cpan packet in order also to learn.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
