package Dist::Zilla::Plugin::SetEnv;

our $DATE = '2016-10-08'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::BeforeMint',
    'Dist::Zilla::Role::BeforeRelease',
    'Dist::Zilla::Role::ModuleMaker',
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::EncodingProvider',
    'Dist::Zilla::Role::FilePruner',
    'Dist::Zilla::Role::VersionProvider',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::PrereqSource',
    'Dist::Zilla::Role::MetaProvider',
    'Dist::Zilla::Role::InstallTool',
    'Dist::Zilla::Role::BeforeArchive',
    'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::AfterMint',
    'Dist::Zilla::Role::AfterRelease',

    # not relevant for reporting phase
    #'Dist::Zilla::Role::BuildRunner',
    #'Dist::Zilla::Role::TestRunner',
    #'Dist::Zilla::Role::FileFinder',
    #'Dist::Zilla::Role::FileFinderUser',
    #'Dist::Zilla::Role::ConfigDumper',
    #'Dist::Zilla::Role::MintingProfile',
    #'Dist::Zilla::Role::MintingProfile::ShareDir',
    #'Dist::Zilla::Role::Releaser',
    #'Dist::Zilla::Role::ShareDir',
);

sub before_build {
    my ($self) = @_;

    $ENV{DZIL} = 1;
    $ENV{DZIL_PHASE} = 'before_build';
    $ENV{DZIL_NAME}  = $self->zilla->name;

    my @callers;
    {
        my $i = 0;
        while (1) {
            my @caller = caller($i);
            last unless @caller;
            push @callers, \@caller;
            $i++;
        }
    }

    # a hack
    $ENV{DZIL_TESTING} = 1 if grep {
        $_->[3] eq 'Dist::Zilla::Dist::Builder::test' } @callers;
}

sub before_mint {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'before_mint';
}

sub before_release {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'before_release';
}

sub make_module {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'make_module';
}

sub gather_files {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'gather_files';
}

sub set_file_encodings {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'set_file_encodings';
}

sub prune_files {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'prune_files';
}

sub provide_version {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'provide_version';

    undef;
}

sub munge_files {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'munge_files';
}

sub register_prereqs {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'register_prereqs';
}

sub metadata {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'provide_meta';
    {};
}

sub setup_installer {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'setup_installer';
}

sub before_archive {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'before_archive';
}

sub after_build {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'after_build';
}

sub after_release {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'after_release';
}

sub after_mint {
    my ($self) = @_;

    $ENV{DZIL_PHASE} = 'after_mint';
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Set various environment variables

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::SetEnv - Set various environment variables

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Plugin::SetEnv (from Perl distribution Dist-Zilla-Plugin-SetEnv), released on 2016-10-08.

=head1 SYNOPSIS

In F<dist.ini>:

 [SetEnv]

=head1 DESCRIPTION

This plugin sets various environment variables so when one of your plugins runs
another program or script, the program can get various information about
Dist::Zilla or the building process through the environment variables.

Plugin ordering is important. Generally you should put this SetEnv plugin
I<before> any other plugin that you might want to run programs from, so SetEnv
already has the chance to set e.g. C<DZIL_PHASE>.

=for Pod::Coverage .+

=head1 ENVIRONMENT

=head2 DZIL => bool

Can be used by programs/scripts to tell that they are running under Dist::Zilla.

This is set to 1 at the "before build" phase.

=head2 DZIL_NAME => set

Can be used by programs/scripts to tell what distribution is being built.

This is set to C<< $zilla->name >> at the "before build" phase.

Example: C<App-YourApp>

=head2 DZIL_PHASE => str

Can be used by programs/scripts to tell what phase they are in.

This is set to C<before_build> at the "before build" phase.

Set to C<before_mint> at the "before mint" phase.

Set to C<before_release> at the "before release" phase.

Set to C<make_module> at the "make module" (ModuleMaker) phase.

Set to C<gather_files> at the "file gathering" phase.

Set to C<set_file_encodings> at the "set file encodings" phase.

Set to C<prune_files> at the "file pruning" phase.

Set to C<provide_version> at the "provide version" phase.

Set to C<munge_files> at the "file munging" phase.

Set to C<register_prereqs> at the "register prereqs" phase.

Set to C<provide_meta> at the "meta provider" phase.

Set to C<setup_installer> at the "setup installer" phase.

Set to C<before_archive> at the "before archive" phase.

Set to C<after_build> at the "after build" phase.

Set to C<after_mint> at the "after mint" phase.

Set to C<after_release> at the "after release" phase.

=head2 DZIL_NAME => str

This is set to 1 at the "before build" phase.

=head2 DZIL_RELEASING => bool

Included for completeness. This is not set by this plugin, but by L<Dist::Zilla>
itself at the beginning of the release process.

Can be used by programs/scripts to tell that they are in a release process.

=head2 DZIL_TESTING => bool

Can be used by programs/scripts to tell that they are in a test process.

Conditionally set to 1 at the "before build" phase.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-SetEnv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-SetEnv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-SetEnv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::ReportPhase>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
