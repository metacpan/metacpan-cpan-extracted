use 5.14.0;

package Map::Metro::Plugin::Map::Madrid;

# ABSTRACT: Map::Metro map for Madrid
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1002';

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Plugin::Map::Madrid - Map::Metro map for Madrid



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.16+-blue.svg" alt="Requires Perl 5.16+" />
<a href="https://travis-ci.org/Csson/p5-Map-Metro-Madrid"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Madrid.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Map-Metro-Plugin-Map-Madrid-0.1002"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Map-Metro-Plugin-Map-Madrid/0.1002" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Map-Metro-Plugin-Map-Madrid%200.1002"><img src="http://badgedepot.code301.com/badge/cpantesters/Map-Metro-Plugin-Map-Madrid/0.1002" alt="CPAN Testers result" /></a>
</p>

=end html

=head1 VERSION

Version 0.1002, released 2019-05-31.

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

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
