use 5.10.0;
use strict;
use warnings;

package Map::Metro::Plugin::Map::Helsinki;

# ABSTRACT: Map::Metro map for Helsinki
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1987';

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-helsinki.metro',
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

Map::Metro::Plugin::Map::Helsinki - Map::Metro map for Helsinki



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Map-Metro-Helsinki"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Helsinki.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Map-Metro-Plugin-Map-Helsinki-0.1987"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Map-Metro-Plugin-Map-Helsinki/0.1987" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Map-Metro-Plugin-Map-Helsinki%200.1987"><img src="http://badgedepot.code301.com/badge/cpantesters/Map-Metro-Plugin-Map-Helsinki/0.1987" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-88.2%-orange.svg" alt="coverage 88.2%" />
</p>

=end html

=head1 VERSION

Version 0.1987, released 2016-10-30.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Helsinki')->parse;

    my $graph2 = Map::Metro->new('Helsinki', hooks => 'Helsinki::Swedish')->parse;
    # now the station names are in Swedish

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

This distribution also includes the C<Map::Metro::Plugin::Hook::Helsinki::Swedish> hook, which if applied
translates all station names into Swedish.

=head1 Status

See L<Map::Metro::Plugin::Map::Helsinki::Lines>

This map includes:

=over 4

=item *

The two branches of the Helsinki metro [L<wikipedia|https://en.wikipedia.org/wiki/Helsinki_Metro>]

=back

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Helsinki/master/static/images/helsinki.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Helsinki/master/static/images/helsinki.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Helsinki>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Helsinki>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
