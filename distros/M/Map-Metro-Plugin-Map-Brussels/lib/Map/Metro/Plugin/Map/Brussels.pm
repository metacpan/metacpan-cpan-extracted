use 5.14.0;
use strict;
use warnings;

package Map::Metro::Plugin::Map::Brussels;

our $VERSION = '0.1001'; # VERSION
# ABSTRACT: Map::Metro map for Brussels

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-brussels.metro',
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

=encoding UTF-8

=head1 NAME

Map::Metro::Plugin::Map::Brussels - Map::Metro map for Brussels

=head1 VERSION

Version 0.1001, released 2015-02-03.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Brussels')->parse;

Or:

    map-metro.pl route Brussels "Gare de l'Ouest" 'Centraal Station'

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

This map L<contains|Map::Metro::Plugin::Map::Brussels::Lines>:

=over 4

=item *

The four metro lines I<L1>, I<L2>, I<L5> and I<L6> [L<wikipedia|https://en.wikipedia.org/wiki/Brussels_Metro>]

=item *

The I<T3> tram line, but only between I<Gare du Nord/Noordstation> and I<Albert> [L<wikipedia|https://en.wikipedia.org/wiki/Brussels_tram_route_3>]

=back

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Brussels/master/static/images/brussels.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Brussels/master/static/images/brussels.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Brussels>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Brussels>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
