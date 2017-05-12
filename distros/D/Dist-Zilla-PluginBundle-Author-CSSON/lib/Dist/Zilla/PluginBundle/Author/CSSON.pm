use 5.10.0;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Author::CSSON;

# ABSTRACT: Dist::Zilla plugin list (deprecated)
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1103';

use Moose;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str Int/;
with 'Dist::Zilla::Role::PluginBundle::Easy';
with 'Dist::Zilla::Role::PluginBundle::PluginRemover';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';

use namespace::autoclean;
use List::AllUtils 'none';
use Config::INI;
use Path::Tiny;

has installer => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    default => sub { shift->payload->{'installer'} || 'ModuleBuildTiny' },
);
has is_private => (
    is => 'rw',
    isa => Int,
    lazy => 1,
    default => sub { shift->payload->{'is_private'} || 0 },
);
has is_task => (
    is => 'rw',
    isa => Int,
    lazy => 1,
    default => sub { shift->payload->{'is_task'} || 0 },
);
has weaver_config => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    default => sub { shift->payload->{'weaver_config'} || '@Author::CSSON' },
);
has homepage => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    builder => 1,
);
has has_travis => (
    is => 'rw',
    isa => Int,
    lazy => 1,
    default => sub { shift->payload->{'has_travis'} || 0 },
);


sub _build_homepage {
    my $distname;
    if(path('iller.ini')->exists) {
        $distname = Config::INI::Reader->read_file('iller.ini')->{'_'}{'name'};
    }
    elsif(path('dist.ini')->exists) {
        $distname = Config::INI::Reader->read_file('dist.ini')->{'_'}{'name'};
    }
    return sprintf 'https://metacpan.org/release/' . $distname;
}

sub build_file {
    my $self = shift;

    return $self->installer =~ m/MakeMaker/ ? 'Makefile.PL' : 'Build.PL';
}

sub configure {
    my $self = shift;

    my @possible_installers = qw/MakeMaker MakeMaker::IncShareDir ModuleBuild ModuleBuildTiny/;
    if(none { $self->installer eq $_ } @possible_installers) {
        die sprintf '%s is not one of the possible installers (%s)', $self->installer, join ', ' => @possible_installers;
    }

    $self->add_plugins(
        ['Git::GatherDir', { exclude_filename => [
                                'META.json',
                                'LICENSE',
                                'README.md',
                                'iller.ini',
                                $self->build_file,
                            ] },
        ],
        ['CopyFilesFromBuild', { copy => [
                                   'META.json',
                                   'LICENSE',
                                   $self->build_file,
                               ] },
        ],
        ['ReversionOnRelease', { prompt => 1 } ],
        ['OurPkgVersion'],
        ['PodnameFromClassname'],
        ['NextRelease', { format => '%v  %{yyyy-MM-dd HH:mm:ss VVV}d' } ],
        ['PreviousVersion::Changelog'],

        ['NextVersion::Semantic', { major => '',
                                    minor => "API Changes, New Features, Enhancements",
                                    revision => "Requirements, Testing, Revision, Bug Fixes, Documentation, Meta",
                                    format => '%d.%02d%02d',
                                    numify_version => 0,
                                  }
        ],
        ['Iller::CleanupDistIni'],
        (
            $self->is_task ?
            ['TaskWeaver']
            :
            ['PodWeaver', { config_plugin => $self->weaver_config } ]
        ),
        ['Git::Check', { allow_dirty => [
                           'dist.ini',
                           'Changes',
                           'META.json',
                           'README.md',
                           'README',
                           $self->build_file,
                       ] },
        ],
        (
            $self->is_private ?
            ()
            :
            ['GithubMeta', { issues => 1, homepage => $self->homepage } ]
        ),
        ['Readme'],
        ['ReadmeAnyFromPod', { filename => 'README.md',
                               type => 'markdown',
                               location => 'root',
                             }
        ],
        ['MetaNoIndex', { directory => [qw/t xt inc share eg examples/] } ],
        ['Prereqs::FromCPANfile'],
        [ $self->installer ],
        ['MetaJSON'],
        ['MetaProvides::Class'],
        ['MetaProvides::Package'],
        ['ContributorsFromGit'],
        (
            $ENV{'ILLERAT'} || $ENV{'ILLER_AUTHOR_TEST'} ?
            (
            ['Test::Kwalitee::Extra'],
            ['Test::NoTabs'],
            ['Test::EOL'],
            ['Test::EOF'],
            ['Test::Version'],
            )
            :
            ()
        ),
        ['PodSyntaxTests'],
        ['MetaYAML'],
        ['License'],
        ['ExtraTests'],

        ['ShareDir'],
        ['ExecDir'],
        ['Manifest'],
        ['ManifestSkip'],
        ['CheckChangesHasContent'],
        ['TestRelease'],
        ['ConfirmRelease'],
        [ $ENV{'FAKE_RELEASE'} ? 'FakeRelease' : $self->is_private ? 'UploadToStratopan' : 'UploadToCPAN' ],
        (
            $self->has_travis ?

            ['TravisYML']
            :
            ()
        ),
        ['Git::Tag', { tag_format => '%v',
                       tag_message => ''
                     }
        ],
        ['Git::Push', { remotes_must_exist => 1 } ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::CSSON - Dist::Zilla plugin list (deprecated)

=head1 VERSION

Version 0.1103, released 2016-02-18.

=head1 STATUS

Deprecated. See L<Dist::Iller::Config::Author::CSSON> instead.

=head1 SOURCE

Source repository is at L<https://github.com/CSSON/p5-Dist-Zilla-PluginBundle-Author-CSSON>.

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-PluginBundle-Author-CSSON>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
