package Dist::Zilla::PluginBundle::Author::PERLANCAR;

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::PluginBundle::Filter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-01'; # DATE
our $DIST = 'Dist-Zilla-PluginBundle-Author-PERLANCAR'; # DIST
our $VERSION = '0.609'; # VERSION

sub configure {
    my $self = shift;

    # we want these to be loaded early
    $self->add_plugins(
        'PERLANCAR::CheckPendingRelease', # before ConfirmRelease
    );

    $self->add_bundle(Filter => {
        -bundle => '@Classic',
        -remove => [qw/PkgVersion PodVersion Readme UploadToCPAN/],
    });

    $self->add_plugins(
        ['ExecDir' => 'ExecDir script' => {dir=>'script'}],
        'PERLANCAR::BeforeBuild',
        'Rinci::AbstractFromMeta',
        'PodnameFromFilename',
        #'PERLANCAR::CheckDepDists', # 2016-03-16 disabled because it slows down building process, i'll do this occasionally later
        'PERLANCAR::EnsurePrereqToSpec',
        'PERLANCAR::MetaResources',
        'CheckChangeLog',
        'CheckMetaResources',
        'CheckSelfDependency',
        'Git::Contributors',
        'CopyrightYearFromGit',
        'IfBuilt',
        'MetaJSON',
        'MetaConfig',
        'MetaProvides::Package',
        #'GenShellCompletion', # 2017-07-07 - disabled because i want to use DZP:StaticInstall to set x_static_install whenever possible. DZP:StaticInstall doesn't allow InstallTool plugins other than from MakeMaker and ModuleBuildTiny
        ['PERLANCAR::Authority' => {locate_comment=>1}],
        'OurDate',
        'OurDist',
        ['OurPkgVersion' => {overwrite=>1}],
        'PodWeaver',
        ['PruneFiles' => {match => ['~$', '^nytprof.*']}],
        'Pod2Readme',
        'Rinci::AddPrereqs',
        'Rinci::AddToDb',
        'Rinci::EmbedValidator',
        'SetScriptShebang',
        'Test::Compile',
        'Test::Perl::Critic::Subset',
        'Test::Rinci',
        'StaticInstall', # by default enable static install because 99% of the time my dist is pure-perl
        'EnsureSQLSchemaVersionedTest',
        ['Acme::CPANModules::Blacklist' => {module=>[q[PERLANCAR::Avoided], q[PERLANCAR::MyRetired]]}],
        'Prereqs::EnsureVersion',
        'Prereqs::CheckCircular',
        'UploadToCPAN::WWWPAUSESimple',
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
# ABSTRACT: Dist::Zilla like PERLANCAR when you build your dists

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::PERLANCAR - Dist::Zilla like PERLANCAR when you build your dists

=head1 VERSION

This document describes version 0.609 of Dist::Zilla::PluginBundle::Author::PERLANCAR (from Perl distribution Dist-Zilla-PluginBundle-Author-PERLANCAR), released on 2023-11-01.

=head1 SYNOPSIS

 # dist.ini
 [@Author::PERLANCAR]

is equivalent to (see source).

=head1 DESCRIPTION

The gist:

I avoid stuffs that might change line numbers (so OurPkgVersion instead of
PkgVersion, etc). I also always add #ABSTRACT, #PODNAME, and POD at the end of
file).

I still maintain dependencies and increase version number manually (so no
AutoVersion and AutoPrereqs).

I install my dists after release (the eat-your-own-dog-food principle), except
when INSTALL=0 environment is specified. I also archive them using a script
called C<archive-perl-release>. This is currently a script on my computer, you
can get them from my 'scripts' github repo but this is optional and the release
process won't fail if the script does not exist.

There are extra stuffs related to L<Rinci>, which should have no effect if you
are not using any Rinci metadata in the code.

There are extra stuffs related to checking prerequisites: I have a blacklist of
prerequisites to avoid so
L<[Acme::CPANModules::Blacklist]|Dist::Zilla::Plugin::Acme::CPANModules::Blacklist>
will fail the build if any of the blacklisted modules are used as a prerequisite
(unless the prerequisite is explicitly whitelisted by
L<[Acme::CPANModules::Whitelist]|Dist::Zilla::Plugin::Acme::CPANModules::Whitelist>).
I avoid circular dependencies using
L<[Prereqs::CheckCircular]|Dist::Zilla::Plugin::Prereqs::CheckCircular>. And I
also maintain a file called F<pmversions.ini> where I put minimum versions of
some modules and check this using
L<[Prereqs::EnsureVersion]|Dist::Zilla::Plugin::Prereqs::EnsureVersion>.

=for Pod::Coverage ^(configure)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-PluginBundle-Author-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-PluginBundle-Author-PERLANCAR>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alexandr Ciornii José Joaquín Atria Steven Haryanto

=over 4

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

José Joaquín Atria <jjatria@gmail.com>

=item *

Steven Haryanto <stevenharyanto@gmail.com>

=back

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
