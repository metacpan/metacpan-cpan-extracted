use 5.14.0;

package Map::Metro::Plugin::Map::Madrid;

our $VERSION = '0.1001'; # VERSION

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-madrid.metro',
);
sub map_version {
    return $VERSION;
}
sub map_package {
    return __PACKAGE__;
}

1;

# ABSTRACT: Map::Metro map for Madrid

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Plugin::Map::Madrid - Map::Metro map for Madrid

=head1 VERSION

Version 0.1001, released 2015-03-20.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Madrid')->parse;

Or

    $ map-metro.pl route Madrid "Campo de las Naciones" "Puente de Vallecas"

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

L<Map::Metro::Plugin::Map::Madrid::Lines>

As of 2015-jan-07 it contains:

=over 4

=item *

The twelve metro lines + Ramal [L<wikipedia|https://en.wikipedia.org/wiki/Madrid_Metro>]

=back

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Madrid/master/static/images/madrid.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Madrid/master/static/images/madrid.png" style="max-width: 600px" /></a></p>

=head1 SEE ALSO

=over 4

=item *

L<Map::Metro>

=item *

L<Task::MapMetro::Maps>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Madrid>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Madrid>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
