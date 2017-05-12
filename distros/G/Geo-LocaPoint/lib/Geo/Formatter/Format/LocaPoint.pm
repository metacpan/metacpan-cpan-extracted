package Geo::Formatter::Format::LocaPoint;

use strict;
use warnings;
use Carp;
use base qw(Geo::Formatter::FormatBase::Single);
use Geo::LocaPoint;

use version; our $VERSION = qv('0.0.4');

sub encode {
    latlng2locapoint(@_[1..2]);
}

sub decode {
    locapoint2latlng($_[1]);
}

1;

__END__

=head1 NAME

Geo::Formatter::Format::LocaPoint - Add locapoint format to Geo::Formatter


=head1 SYNOPSIS

  use Geo::Formatter qw(LocaPoint);

  # Latitude/longitude (WGS84/degree, plus as E and N, minus as W and S)
  my ($lat,$lng) = (35.000,135.000);

  # Encode latitude/longitude to LocaPoint
  my $locapo = latlng2format( 'locapoint', $lat, $lng );

  # Decode LocaPoint to latitude/longitude
  ($lat,$lng) = format2latlng( 'locapoint', $locapo );


=head1 DESCRIPTION

This module add locapoint format to Geo::Formatter.


=head1 METHOD

=over

=item * encode

=item * decode

=back


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>.

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

