package Geo::Coder::Google;

use strict;
use warnings;
our $VERSION = '0.18';

sub new {
    my ($self, %param) = @_;
    my $apiver = delete $param{apiver} || 3;
    my $class = 'Geo::Coder::Google::V' . $apiver;

    eval "require $class"; die $@ if $@;
    $class->new(%param);
}

1;
__END__

=head1 NAME

Geo::Coder::Google - Google Maps Geocoding API

=head1 DESCRIPTION

Geo::Coder::Google provides a geocoding functionality using Google Maps API.

See L<Geo::Coder::Google::V2> for V2 API usage.

See L<Geo::Coder::Google::V3> for V3 API usage.

B<Note that Google no longer supports the V2 API. Geo::Coder::Google defaults 
to the V3 API. The V2 interface is still here but any attempts to use it will
fail since the V2 API service is no longer reachable.>

=head1 LICENSE

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
