package Geo::Google::MyMap::KMLURL;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');
use base 'Exporter';

our @EXPORT = qw(
    mymap2kmlurl
);

sub mymap2kmlurl {
    my $input = shift;

    my ( $msid ) = $input =~ /(?:^|msid=)([0-9]{21}\.[0-9a-f]{21})(?:$|&)/;

    croak "Cannot find msid from argument" unless ( $msid );

    "http://maps.google.co.jp/maps/ms?msa=0&msid=$msid&output=kml&ge_fileext=.kml";
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::Google::MyMap::KMLURL - Create URL for downloading Full-spec KML from Google MyMap msid


=head1 SYNOPSIS

    use Geo::Google::MyMap::KMLURL;

    # Argument is msid or MyMap's 'Show by Google Earth' URL
    my $kmlurl = mymap2kmlurl( $msid );

  
=head1 DESCRIPTION

    Google MyMap does not provide URL for downloadming full-spec KML.
    This module create it from MyMap's msid.


=head1 EXPORT 

=over

=item C<< mymap2kmlurl >>

=back


=head1 DEPENDENCIES

None.


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
