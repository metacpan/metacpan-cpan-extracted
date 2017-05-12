use 5.14.0;

package Dist::Zilla::Plugin::MapMetro::MintMapFiles;

our $VERSION = '0.1500'; # VERSION

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::TextTemplate';

override 'merged_section_data' => sub {
    my $self = shift;

    my $data = super;
    for my $name (keys %{ $data }) {
        my $city = $self->zilla->name;
        $city =~ s{^Map-Metro-Plugin-Map-}{};

        $data->{ $name } = \$self->fill_in_string(
            ${ $data->{ $name } }, {
                dist => \($self->zilla),
                city => \$city,
                plugin => \($self),
            },
        );
    }
    return $data;
};

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MapMetro::MintMapFiles

=head1 VERSION

Version 0.1500, released 2015-02-01.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-MintingProfile-MapMetro-Map>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-MintingProfile-MapMetro-Map>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ Changes ]__
Revision history for {{ $dist->name }}

{{ '{{$NEXT}}' }}
   - Initial release
__[ .gitignore ]__
/{{ $dist->name }}-*
/.build
/_build*
/Build
MYMETA.*
!META.json
/.prove
__[ cpanfile ]__
requires 'perl', '5.014000';

requires 'Moose::Role', '2.0000';
requires 'Map::Metro', '0.1900';
__[ t/basic.t ]__
use strict;
use Test::More;

use Map::Metro;

my $graph = Map::Metro->new('{{ $city }}')->parse;
my $routing = $graph->routing_for(qw/1 3/);

is $routing->get_route(0)->get_step(0)->origin_line_station->station->name, '<<Name of first station in route>>', 'Found route';

# more tests

done_testing;
__[ dist.ini ]__
name = {{ $dist->name }}
author = {{ $dist->authors->[0] }}
license = Perl_5
copyright_holder = {{ $dist->authors->[0] }}

[Git::GatherDir]
exclude_filename = META.json
exclude_filename = LICENSE
exclude_filename = README.md
exclude_filename = Build.PL

[CopyFilesFromBuild]
copy = META.json
copy = LICENSE
copy = Build.PL

[ReversionOnRelease]
prompt = 1

[OurPkgVersion]

[NextRelease]
format = %v  %{yyyy-MM-dd HH:mm:ss VVV}d

[PreviousVersion::Changelog]

[NextVersion::Semantic]
format = %d.%02d%02d
major =
minor = API Changes, New Features, Enhancements
numify_version = 0
revision = Revision, Bug Fixes, Documentation, Meta

[Git::Check]
allow_dirty = dist.ini
allow_dirty = Changes
allow_dirty = META.json
allow_dirty = README.md
allow_dirty = Build.PL

[GithubMeta]
issues = 1

[ReadmeAnyFromPod]
filename = README.md
location = root
type = markdown

[MetaNoIndex]
directory = t
directory = xt
directory = inc
directory = share
directory = eg
directory = examples

[Prereqs::FromCPANfile]

[ModuleBuildTiny]

[MetaJSON]

[ContributorsFromGit]

[PodWeaver]

[PodSyntaxTests]

[MetaYAML]

[License]

[ExtraTests]

[ShareDir]

[ExecDir]

[Manifest]

[ManifestSkip]

[CheckChangesHasContent]

[TestRelease]

[ConfirmRelease]

[UploadToCPAN]

[Git::Tag]
tag_format = %v
tag_message =

[Git::Push]
remotes_must_exist = 1

[MapMetro::MakeLinePod]
