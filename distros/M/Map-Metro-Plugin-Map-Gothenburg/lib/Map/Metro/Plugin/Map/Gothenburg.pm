use 5.14.0;
use warnings;

package Map::Metro::Plugin::Map::Gothenburg;

our $VERSION = '0.1004'; # VERSION
# ABSTRACT: Map::Metro map for Gothenburg

use Moose;
use namespace::autoclean;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-gothenburg.metro',
);
sub map_version {
    return $VERSION;
}
sub map_package {
    return __PACKAGE__;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Map::Metro::Plugin::Map::Gothenburg - Map::Metro map for Gothenburg



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.16+-brightgreen.svg" alt="Requires Perl 5.16+" /> <a href="https://travis-ci.org/Csson/p5-Map-Metro-Gothenburg"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Gothenburg.svg?branch=master" alt="Travis status" /></a> </p>

=end HTML


=begin markdown

![Requires Perl 5.16+](https://img.shields.io/badge/perl-5.16+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Map-Metro-Gothenburg.svg?branch=master)](https://travis-ci.org/Csson/p5-Map-Metro-Gothenburg) 

=end markdown

=head1 VERSION

Version 0.1004, released 2016-01-23.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Gothenburg')->parse;

Or:

	$ map-metro.pl route Gothenburg Saltholmen Torp

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

This map L<contains|Map::Metro::Plugin::Map::Gothenburg::Lines>:

=over 4

=item *

All twelve regular tram lines [L<wikipedia|https://en.wikipedia.org/wiki/Gothenburg_tram_network>]

=back

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Gothenburg/master/static/images/gothenburg.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Gothenburg/master/static/images/gothenburg.png" style="max-width: 600px" /></a></p>

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Gothenburg>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Gothenburg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
