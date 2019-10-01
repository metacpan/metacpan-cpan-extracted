use 5.14.0;

package Map::Metro::Plugin::Map::Lille;

# ABSTRACT: Map::Metro map for Lille
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1003';

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-lille.metro',
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

Map::Metro::Plugin::Map::Lille - Map::Metro map for Lille



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.16+-blue.svg" alt="Requires Perl 5.16+" />
<a href="https://travis-ci.org/Csson/p5-Map-Metro-Lille"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Lille.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Map-Metro-Plugin-Map-Lille-0.1003"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Map-Metro-Plugin-Map-Lille/0.1003" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Map-Metro-Plugin-Map-Lille%200.1003"><img src="http://badgedepot.code301.com/badge/cpantesters/Map-Metro-Plugin-Map-Lille/0.1003" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-69.2%-red.svg" alt="coverage 69.2%" />
</p>

=end html

=head1 VERSION

Version 0.1003, released 2019-09-29.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Lille')->parse;

Or

	$ map-metro.pl route Lille "Gambetta" "Lille Grand Palais"

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

L<Map::Metro::Plugin::Map::Lille::Lines>

This map includes:

=over 4

=item *

The two metro lines [L<wikipedia|https://en.wikipedia.org/wiki/Lille_Metro>]

=back

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Lille/master/static/images/lille.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Lille/master/static/images/lille.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Lille>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Lille>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
