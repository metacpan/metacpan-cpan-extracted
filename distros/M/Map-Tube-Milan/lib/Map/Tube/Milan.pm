use strict;
use warnings;
package Map::Tube::Milan;
$Map::Tube::Milan::VERSION = '0.006';
use 5.010_000;
# ABSTRACT: Interface to the Milan tube map

use File::Share qw<:all>;
use Moo;
use namespace::autoclean;

has json => (is => 'ro', default => sub { dist_file('Map-Tube-Milan','milan.json') });

with 'Map::Tube';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Tube::Milan - Interface to the Milan tube map

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Map::Tube::Milan;
    my $tube = Map::Tube::Milan->new();
 
    my $route = $tube->get_shortest_route('Romolo', 'Lambrate F.S.');
 
    print "Route: $route\n";

=head1 DESCRIPTION

This module allows to find the shortest route between any two given tube
stations in Milan. All interesting methods are provided by the role L<Map::Tube>.

=head1 METHODS

=head2 CONSTRUCTOR

    use Map::Tube::Milan;
    my $tube = Map::Tube::Milan->new();

The only argument, C<json>, is optional; if specified, it should be a code ref
to a function that returns either the path the JSON map file, or a string
containing this JSON content. The default is the path to F<milan.json>
that is a part of this distribution. For further information see L<Map::Tube>.

=head2 json()

This read-only accessor returns whatever was specified as the JSON source at
construction.

=head1 ERRORS

If something goes wrong, maybe because the map information file was corrupted,
the constructor will die.

=head1 SEE ALSO

L<Map::Tube>, L<Map::Tube::GraphViz>.

=head1 AUTHOR

Marco Fontani <MFONTANI@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Marco Fontani <MFONTANI@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
