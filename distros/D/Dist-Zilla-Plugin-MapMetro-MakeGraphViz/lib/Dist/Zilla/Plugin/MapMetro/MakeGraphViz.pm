use 5.14.0;
use warnings;

package Dist::Zilla::Plugin::MapMetro::MakeGraphViz;

# ABSTRACT: Automatically creates a GraphViz2 visualisation of a Metro::Map map
our $VERSION = '0.1104';

use Moose;
use namespace::autoclean;
use Path::Tiny;
use MooseX::AttributeShortcuts;
use Types::Standard qw/HashRef ArrayRef Str Maybe/;
use Map::Metro::Shim;
use GraphViz2;
use Dist::Zilla::Plugin::MapMetro::MakeGraphViz::Map;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::BeforeBuild
/;

sub before_build {
    my $self = shift;

    if(!$ENV{'MMVIZ'} && !$ENV{'MMVIZDEBUG'}) {
        $self->log('Set either MMVIZ or MMVIZDEBUG to a true value to run this.');
        return;
    }

    my @maps = sort { $a cmp $b } map { $_->basename(qr/\.pm/) } path(qw/lib Map Metro Plugin Map/)->children(qr/\.pm/);
    return if !scalar @maps;

    for my $mapname (@maps) {
        state $counter = 0;
        ++$counter;
        $self->log("Works on $mapname [$counter/@{[ scalar @maps ]}]");
        my $map = Dist::Zilla::Plugin::MapMetro::MakeGraphViz::Map->new(map => $mapname);

        if($map->has_generated_file) {
            $self->log("  Saved in @{[ $map->generated_file ]}");
        }
        else {
            $self->log("! Did not create graphviz");
        }
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::MapMetro::MakeGraphViz - Automatically creates a GraphViz2 visualisation of a Metro::Map map



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.14+-brightgreen.svg" alt="Requires Perl 5.14+" /> <a href="https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-mapMetro-MakeGraphViz"><img src="https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-mapMetro-MakeGraphViz.svg?branch=master" alt="Travis status" /></a> <img src="https://img.shields.io/badge/coverage-0.0%-red.svg" alt="coverage 0.0%" /></p>

=end HTML


=begin markdown

![Requires Perl 5.14+](https://img.shields.io/badge/perl-5.14+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-mapMetro-MakeGraphViz.svg?branch=master)](https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-mapMetro-MakeGraphViz) ![coverage 0.0%](https://img.shields.io/badge/coverage-0.0%-red.svg)

=end markdown

=head1 VERSION

Version 0.1104, released 2016-02-07.

=head1 SYNOPSIS

  ;in dist.ini
  [MapMetro::MakeGraphViz]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin creates a L<GraphViz2> visualisation of a L<Map::Metro> map, and is only useful in such a distribution.

=head1 SEE ALSO

=over 4

=item *

L<Task::MapMetro::Dev> - Map::Metro development tools

=item *

L<Map::Metro>

=item *

L<Map::Metro::Plugin::Map>

=item *

L<Map::Metro::Plugin::Map::Stockholm> - An example

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-mapMetro-MakeGraphViz>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-MapMetro-MakeGraphViz>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
