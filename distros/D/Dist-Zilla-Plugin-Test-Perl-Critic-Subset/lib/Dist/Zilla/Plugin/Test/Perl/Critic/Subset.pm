package Dist::Zilla::Plugin::Test::Perl::Critic::Subset;
# ABSTRACT: Tests to check your code against best practices
use 5.008;
use strict 'subs', 'vars';
use warnings;

#our $VERSION = '3.002';

our $VERSION = '3.001.006'; # VERSION

use Moose;
use Path::Tiny;
use Moose::Util qw( get_all_attribute_values );

use Data::Dumper;
use Dist::Zilla::File::InMemory;
use Sub::Exporter::ForMethods 'method_installer';
use Data::Section 0.004 { installer => method_installer }, '-setup';
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(ArrayRef RegexpRef Str);
use namespace::autoclean;

# and when the time comes, treat them like templates
with (
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::FileFinderUser' => {
        method          => 'found_files',
        finder_arg_names => [ 'finder' ],
        default_finders => [ ':InstallModules', ':ExecFiles', ':TestFiles' ],
    },
    'Dist::Zilla::Role::PrereqSource',
);

has critic_config => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => 'perlcritic.rc',
);

has files => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { files => 'elements' },
    lazy => 1,
    default => sub { [] },
);

has dirs => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { dirs => 'elements' },
    lazy => 1,
    default => sub { [] },
);

{
    my $type = subtype as ArrayRef[RegexpRef];
    coerce $type, from ArrayRef[Str], via { [map { qr/$_/ } @$_] };

    has skips => (
        isa => $type,
        coerce => 1,
        traits => ['Array'],
        handles => { skips => 'elements' },
        lazy => 1,
        default => sub { ['^lib/Bencher/ScenarioR/', '^t/'] },
    );
}

has _file_obj => (
    is => 'rw', isa => role_type('Dist::Zilla::Role::File'),
);

sub mvp_multivalue_args { qw(files dirs skips) }
sub mvp_aliases { return { file => 'files', dir => 'dirs', skip => 'skips' } }

around dump_config => sub {
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        finder => [ sort @{ $self->finder } ],
        blessed($self) ne __PACKAGE__ ? ( version => ${__PACKAGE__ . "::VERSION"} ) : (),
    };
    return $config;
};

sub gather_files
{
    my $self = shift;

    $self->add_file(
        $self->_file_obj(
            Dist::Zilla::File::InMemory->new(
                name => 'xt/author/critic.t',
                content => ${$self->section_data('xt/author/critic.t')},
            )
        )
    );

    return;
}

sub munge_files {
    my $self = shift;

    my @filenames = map { path($_->name)->relative('.')->stringify }
        grep { not ($_->can('is_bytes') and $_->is_bytes) }
        @{ $self->found_files };
    push @filenames, $self->files;
    push @filenames, $self->dirs;
    for my $skip ($self->skips) {
        @filenames = grep { $_ !~ $skip } @filenames;
    }

    $self->log_debug('adding file/dir ' . $_) foreach @filenames;

    my $file = $self->_file_obj;
    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                dist => \($self->zilla),
                plugin => \$self,
                filenames_dump => Data::Dumper->new([\@filenames])->Terse(1)->Indent(0)->Dump,
            },
        )
    );

    return;
}

sub register_prereqs {
    my $self = shift;

    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::Perl::Critic' => 0,

        # TODO also extract list of policies used in file $self->critic_config
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Perl::Critic::Subset - Tests to check your code against best practices

=head1 VERSION

version 3.001.006

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::Perl::Critic]
    critic_config = perlcritic.rc ; default / relative to project root

    ; to add some files/dirs
    ;file = t/mytest.t
    ;file = t/myothertest.t
    ;dir  = xt

    ; to exclude some files/dirs by regex
    skip  = todo
    skip  = lib/Bencher/ScenarioR/

    ; you can also specify finders to include/exclude files
    ;finder = :TestFiles
    ;finder = :InstallModules

Another example of specifying finders, by defining a custom finder (see
L<Dist::Zilla::Plugin::FileFinder::ByName> for more details):

    [FileFinder::ByName / MyFiles]
    dir = lib
    dir = script
    file = *.t
    skip = lib/Bencher/ScenarioR/

    [Test::Perl::Critic]
    finder = MyFiles

=head1 DESCRIPTION

B<Fork notice:> This is a temporary fork of
L<Dist::Zilla::Plugin::Test::Perl::Critic> 3.001 which includes
L<https://github.com/perlancar/operl-Dist-Zilla-Plugin-Test-Perl-Critic/commit/bd46961d9d7da767f7a431fba13de441db4b6848>
to add C<finder> and C<files> configuration options. These options let you
select, include, exclude files to be tested.

This will provide a F<xt/author/critic.t> file for use during the "test" and
"release" calls of C<dzil>. To use this, make the changes to F<dist.ini>
above and run one of the following:

    dzil test
    dzil release

During these runs, F<xt/author/critic.t> will use L<Test::Perl::Critic> to run
L<Perl::Critic> against your code and by report findings.

This plugin accepts the C<critic_config> option, which specifies your own config
file for L<Perl::Critic>. It defaults to C<perlcritic.rc>, relative to the
project root. If the file does not exist, L<Perl::Critic> will use its defaults.

This plugin is an extension of L<Dist::Zilla::Plugin::InlineFiles>.

=for Pod::Coverage gather_files register_prereqs munge_files mvp_aliases

=head1 CONFIGURATION OPTIONS

=head2 critic_config

Specify a perl critic profile. Will be passed to L<Test::Perl::Critic>'s
C<-profile> import option.

=head2 finder

This is the name of a FileFinder for finding files to check. The default value
is C<:InstallModules>, C<:ExecFiles>, C<:TestFiles> (see also
L<Dist::Zilla::Plugin::ExecDir>); this option can be used more than once.

Other predefined finders are listed in C<default_finders> in
L<Dist::Zilla::Role::FileFinderUser>. You can define your own with the
L<Dist::Zilla::Plugin::FileFinder::ByName> plugin.

=head2 file

A filename to also test, in addition to any files found earlier. This option can
be repeated to specify multiple additional files.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/critic.t ]___
#!perl

use strict;
use warnings;

# this test was generated with {{ ref $plugin }} {{ $plugin->VERSION }}

use Test::Perl::Critic (-profile => "{{ $critic_config }}") x!! -e "{{ $critic_config }}";

my $filenames = {{ $filenames_dump }};
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
