package Flickr::Types::Tools;

use strictures;
use Carp;

our $VERSION = '1.22';

use Type::Library
   -base,
   -declare => qw(
                     FlickrAPI
                     FlickrAPIcameras
                     FlickrAPIargs
                     FlickrPermStr
                     FlickrToken
                     HexNum
);
use Type::Utils -all;
use Types::Standard qw ( Optional Dict Int Str InstanceOf Any );

declare FlickrAPI,
  api => InstanceOf ["Flickr::API"];

declare FlickrAPIcameras, api => InstanceOf ["Flickr::API::Cameras"];

declare HexNum,
      as Str,
      where { /^[a-f0-9]+$/i };

declare FlickrToken,
    as Str,
    where { /^[a-f0-9\-]+$/i };

declare FlickrPermStr,
    as Str,
    where { /none|read|write|delete/i };


declare FlickrAPIargs,
  as Dict [
    consumer_key     => HexNum,
    consumer_secret  => HexNum,
    access_token     => Optional [Any],
    callback         => Optional [Str],
    nonce            => Optional [Str],
    request_method   => Optional [Str],
    request_url      => Optional [Str],
    signature_method => Optional [Str],
    timestamp        => Optional [Int],
    token            => Optional [FlickrToken],
    token_secret     => Optional [HexNum],
    version          => Optional [Str],
  ];

1;

__END__

=head1 NAME

Flickr::Types::Person Type definitions


=head1 VERSION

This document describes Flickr::Types Version 1.22


=head1 SYNOPSIS

    use Flickr::Types qw( PersonSearchDict );
    use Moo;

    has searchkey => (
        is   => 'rw',
        isa  => PersonSearchDict,
        required => 1,
    );



=head1 DESCRIPTION

Type declarations used in various Flickr Person modules


=head1 DEPENDENCIES

Type::Tiny


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-flickr-type@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Louis B. Moore  C<< <lbmoore@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015, Louis B. Moore C<< <lbmoore@cpan.org> >>. All rights reserved.

This module is licensed under the Artistic License 2.0 by The Perl Foundation.
L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Flickr|http://www.flickr.com/>,
L<http://www.flickr.com/services/api/>
L<https://www.flickr.com/services/api/auth.oauth.html>
L<https://github.com/lbmoore/perl-Flickr-Tools>
L<https://github.com/iamcal/perl-Flickr-API>


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
