package Geo::Formatter::Format::GeoPo;

use strict;
use warnings;
use Carp;
use Geo::GeoPo;
use base qw(Geo::Formatter::FormatBase::Single);

use version; our $VERSION = qv('0.0.1');

sub encode {
    my ($class,$lat,$lng,$opt) = @_;

    $opt ||= {};

    my $scale         = delete $opt->{scale}  || croak "Scale value must be set";

    latlng2geopo( $lat, $lng, $scale, $opt );
}

sub decode {
    my $class = shift;

    geopo2latlng( @_ );
}

1;
__END__

=head1 NAME

Geo::Formatter::Format::GeoPo - Add GeoPo format to Geo::Formatter 

=head1 SYNOPSIS

  use Geo::Formatter qw(GeoPo);
  
  my ( $lat, $lng, $scale ) = format2latlng( 'geopo', 'Z4RHXX' );
  # 35.658578, 139.745447, 6

  my ( $lat, $lng, $scale ) = format2latlng( 'geopo', 'http://geopo.at/Z4RHXX' );
  # Same result

  my $geopo = latlng2format( 'geopo', 35.658578, 139.745447, { scale => 6 } );
  # Z4RHXX

  my $geopo = latlng2format( 'geopo', 35.658578, 139.745447, { scale => 6, as_url => 1 } );
  # http://geopo.at/Z4RHXX


=head1 DESCRIPTION

Geo::Formatter::Format::GeoPo adds GeoPo format to Geo::Formatter.


=head1 METHOD

=over

=item * encode

=item * decode

=back


=head1 AUTHOR

OHTSUKA Ko-hei E<lt>nene@kokogiko.netE<gt>


=head1 SEE ALSO

=over

=item * Geo::Formatter

=item * Geo::GeoPo

=back


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
