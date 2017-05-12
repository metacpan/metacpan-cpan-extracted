use 5.10.0;
use strict;
use warnings;

package Map::Metro::Types;

# ABSTRACT: Type library for Map::Metro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use namespace::autoclean;

use Type::Library
    -base,
    -declare => qw/
        Connection
        Line
        LineStation
        Route
        Routing
        Segment
        Station
        Step
        Transfer
    /;

use Type::Utils -all;

class_type Connection   => { class => 'Map::Metro::Graph::Connection' };
class_type Line         => { class => 'Map::Metro::Graph::Line' };
class_type LineStation  => { class => 'Map::Metro::Graph::LineStation' };
class_type Route        => { class => 'Map::Metro::Graph::Route' };
class_type Routing      => { class => 'Map::Metro::Graph::Routing' };
class_type Segment      => { class => 'Map::Metro::Graph::Segment' };
class_type Station      => { class => 'Map::Metro::Graph::Station' };
class_type Step         => { class => 'Map::Metro::Graph::Step' };
class_type Transfer     => { class => 'Map::Metro::Graph::Transfer' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Types - Type library for Map::Metro

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
