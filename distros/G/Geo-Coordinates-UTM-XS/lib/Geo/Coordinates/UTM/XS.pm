package Geo::Coordinates::UTM::XS;

use strict;
use warnings;

use Carp;

BEGIN {

  our $VERSION = '0.04';

  require XSLoader;
  XSLoader::load('Geo::Coordinates::UTM::XS', $VERSION);

}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT  = qw( latlon_to_utm latlon_to_utm_force_zone utm_to_latlon
                   ellipsoid_info ellipsoid_names);

use Geo::Coordinates::UTM;

BEGIN {
    *_cleanup_name = \&Geo::Coordinates::UTM::_cleanup_name;
}

our %_ellipsoid;

my $i = 1;
for (ellipsoid_names) {
    $_ellipsoid{$_} = $i;
    $_ellipsoid{_cleanup_name($_)} = $i;
    # print "ellipsoid info $_: ", join(', ', ellipsoid_info($_)), "\n";
    _set_ellipsoid_info($i, (ellipsoid_info($_))[1,2]);
    $i++;
}

sub _ellipsoid_index {
    my $name = shift;
    my $index = $_ellipsoid{_cleanup_name($name)}
        or croak "bad ellipsoid name '$name'";
    $_ellipsoid{$name} = $index;
}

{
    no warnings;
    *latlon_to_utm = \&_latlon_to_utm;
    *latlon_to_utm_force_zone = \&_latlon_to_utm_force_zone;
    *utm_to_latlon = \&_utm_to_latlon;
}

1;
__END__

=head1 NAME

Geo::Coordinates::UTM::XS - C/XS reimplementation of Geo::Coordinates::UTM

=head1 SYNOPSIS

  # use Geo::Coordinates::UTM;
  use Geo::Coordinates::UTM::XS;
  ...

=head1 DESCRIPTION

This module is a drop in replacement for L<Geo::Coordinates::UTM>.

It's written in C/XS and around 10x-15x times faster than the Perl
implementation.

=head1 SEE ALSO

Read L<Geo::Coordinates::UTM> to learn how to use this module.

=head1 BUGS

Functions to convert coordinates to MGRS available from
Geo::Coordinates::UTM 0.06 are not yet supported.

=head1 AUTHOR

Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2008 by Salvador FandiE<ntilde>o.

Copyright (c) 2007-2008 by Qindel Formacion y Servicios SL.

Copyright (c) 2000, 2002, 2004 by Graham Crookham.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
