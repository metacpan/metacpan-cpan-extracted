use 5.16.0;

package Map::Metro::Plugin::Map::Copenhagen;

our $VERSION = '0.2006'; # VERSION
# ABSTRACT: Map::Metro map for Copenhagen

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-copenhagen.metro',
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

Map::Metro::Plugin::Map::Copenhagen - Map::Metro map for Copenhagen



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.16+-brightgreen.svg" alt="Requires Perl 5.16+" /> <a href="https://travis-ci.org/Csson/p5-Map-Metro-Copenhagen"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro-Copenhagen.svg?branch=master" alt="Travis status" /></a> <img src="https://img.shields.io/badge/coverage-69.2%-red.svg" alt="coverage 69.2%" /></p>

=end HTML


=begin markdown

![Requires Perl 5.16+](https://img.shields.io/badge/perl-5.16+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Map-Metro-Copenhagen.svg?branch=master)](https://travis-ci.org/Csson/p5-Map-Metro-Copenhagen) ![coverage 69.2%](https://img.shields.io/badge/coverage-69.2%-red.svg)

=end markdown

=head1 VERSION

Version 0.2006, released 2016-01-21.

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('Copenhagen')->parse;

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

=head1 Status

This map includes:

=over 4

=item *

Both lines of the Copenhagen metro (L<wikipedia|https://en.wikipedia.org/wiki/Copenhagen_metro>)

=back

=for HTML <p><a href="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Copenhagen/master/static/images/copenhagen.png"><img src="https://raw.githubusercontent.com/Csson/p5-Map-Metro-Copenhagen/master/static/images/copenhagen.png" style="max-width: 600px" /></a></p>

=head1 SEE ALSO

=over 4

=item *

L<Map::Metro>

=item *

L<Task::MapMetro::Maps>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro-Copenhagen>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro-Plugin-Map-Copenhagen>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
