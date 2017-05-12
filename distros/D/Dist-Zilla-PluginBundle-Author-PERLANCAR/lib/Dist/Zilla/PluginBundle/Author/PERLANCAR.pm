package Dist::Zilla::PluginBundle::Author::PERLANCAR;

our $DATE = '2017-02-09'; # DATE
our $VERSION = '0.55'; # VERSION

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::PluginBundle::Filter;

sub configure {
    my $self = shift;

    $self->add_bundle(Filter => {
        -bundle => '@Classic',
        -remove => [qw/PkgVersion PodVersion Readme UploadToCPAN/],
    });

    $self->add_plugins(
        'PERLANCAR::BeforeBuild',
        'Rinci::AbstractFromMeta',
        'PodnameFromFilename',
        #'PERLANCAR::CheckDepDists', # 2016-03-16 disabled because it slows down building process, i'll do this occasionally later
        'PERLANCAR::EnsurePrereqToSpec',
        'PERLANCAR::MetaResources',
        'CheckChangeLog',
        'CheckMetaResources',
        'CopyrightYearFromGit',
        'IfBuilt',
        'MetaJSON',
        'MetaConfig',
        'GenShellCompletion',
        ['Authority' => {locate_comment=>1}],
        'OurDate',
        'OurDist',
        'PERLANCAR::OurPkgVersion',
        'PodWeaver',
        ['PruneFiles' => {match => ['~$', '^nytprof.*']}],
        'ReadmeFromPod',
        'Rinci::AddPrereqs',
        'Rinci::AddToDb',
        'Rinci::Validate',
        'SetScriptShebang',
        'Test::Compile',
        'Test::Rinci',
        'UploadToCPAN::WWWPAUSESimple',
        'EnsureSQLSchemaVersionedTest',
        ['Acme::CPANLists::Blacklist' => {module_list=>[q[PERLANCAR::Avoided::Modules I'm currently avoiding]]}],
        'Prereqs::EnsureVersion',
        'Prereqs::CheckCircular',
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

This document describes version 0.55 of Dist::Zilla::PluginBundle::Author::PERLANCAR (from Perl distribution Dist-Zilla-PluginBundle-Author-PERLANCAR), released on 2017-02-09.

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

=for Pod::Coverage ^(configure)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-PluginBundle-Author-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-PluginBundle-Author-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
