use 5.14.0;

package Map::Metro::Plugin::Map::Barcelona;

our $VERSION = '0.1007'; # VERSION
# ABSTRACT: Map::Metro map for Barcelona

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-barcelona.metro',
);
sub map_version {
    return $VERSION;
}
sub map_package {
    return __PACKAGE__;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Map::Metro::Plugin::Map::Barcelona - Map::Metro map for Barcelona

=head1 VERSION

Version 0.1007, released 2015-02-02.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Barcelona')->parse;

Or:

    $ map-metro.pl route Barcelona Paral·lel Tibidabo
    $ map-metro.pl route Barcelona Parallel Tibidabo

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 STATUS

This map L<contains|Map::Metro::Plugin::Map::Barcelona::Lines>:

=over 4

=item *

The eleven L-lines (L1 to L11) [L<wikipedia|https://en.wikipedia.org/wiki/Barcelona_Metro>]

=item *

The I<Tramvia Blau> [L<wikipedia|https://en.wikipedia.org/wiki/Tramvia_Blau>]

=item *

I<Funicular del Tibidabo> [L<wikipedia|https://en.wikipedia.org/wiki/Funicular_del_Tibidabo>]

=item *

I<Funicular de Montjuïc> [L<wikipedia|https://en.wikipedia.org/wiki/Funicular_de_Montju%C3%AFc>]

=back

=head2 Notes

* L9 and L10 ends at La Sagrera.

* I<Tramvia Blau> only includes the two end-points.

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Barcelona/master/static/images/barcelona.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Barcelona/master/static/images/barcelona.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Barcelona>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Barcelona>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
