package Dist::Zilla::PluginBundle::BESSARABV;
{
  $Dist::Zilla::PluginBundle::BESSARABV::VERSION = '1.0.1';
}
use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

# ABSTRACT: configure Dist::Zilla the way BESSARABV does it


sub configure {
    my $self = shift;

    $self->add_plugins(

        # https://metacpan.org/module/Dist::Zilla::Plugin::GithubMeta
        [ 'GithubMeta' => { issues => 1 } ],

        # https://metacpan.org/module/Dist::Zilla::Plugin::CheckChangesHasContent
        # This is a great thing. It checks that I haven't forgotten to add
        # info to my Changes file
        'CheckChangesHasContent',

        # From [@Basic] - start
        'GatherDir',
        'PruneCruft',
        'ManifestSkip',
        'MetaYAML',
        'License',
        'ExtraTests',
        'ExecDir',
        'ShareDir',
        'MakeMaker',
        'Manifest',
        'TestRelease',
        # 'ConfirmRelease', - moved to BeforeRelease section (I'm asked to
        # enter y/n only if all the tests pass)
        'UploadToCPAN',
        # From [@Basic] - end


        # BeforeBuild

        # FileGatherer

        # ## Testing that Changes file is in right format
        #
        # I have decided to add this test after [Sergey Romanov's pull
        # request][mock_person_pr]. And with [the help of Neil
        # Bowers][changes_dzil_test] I have found this module.
        #
        #  [mock_person_pr]: https://github.com/bessarabov/Mock-Person/pull/3
        #  [changes_dzil_test]: http://questhub.io/realm/perl/quest/51f5f0fa852fe91826000012
        'Test::CPAN::Changes',

        # FilePruner
        'Git::ExcludeUntracked',

        # FileMunger
        'PkgVersion',
        'PodWeaver',
        'NextRelease',

        # PrereqSource
        'AutoPrereqs',

        # TestRunner
        'RunExtraTests',

        # InstallTool

        # AfterBuild

        # BeforeRelease

        # TODO - I want to fail release process if there is already a tag with
        # such version

        [
            # https://metacpan.org/module/Dist::Zilla::Plugin::Git::Check
            # I want my release process fail in case there are some uncommited
            # changes
            'Git::Check' => {

                # it is safe to ignore untracked_files because they are
                # removed by [Git::ExcludeUntracked]
                untracked_files => 'ignore',

                # the default is to allow dirty dist.ini file, but I don't
                # like such choice. I preffer that the build fails if there
                # are some changes in any file in the repo
                allow_dirty => '',

            }
        ],

        # Actually ConfirmRelease in in [@Basic], but I've put it here so the
        # dzil asks for my input only in case eveything else is ok
        'ConfirmRelease',

        # Releaser

        # AfterRelease
        [ 'Git::Tag' => { tag_format => '%v', tag_message => '' } ],

        # TODO - I want to upload new tag to GitHub
    );
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::BESSARABV - configure Dist::Zilla the way BESSARABV does it

=head1 VERSION

version 1.0.1

=head1 DESCRIPTION

In my dist.ini:

    name    = Foo-Bar
    author  = Ivan Bessarabov <ivan@bessarabov.ru>
    license = Perl_5
    copyright_holder = Ivan Bessarabov
    copyright_year   = 2013

    version = 0.01

    [@BESSARABV]

Dist::Zilla::PluginBundle::BESSARABV uses Semantic Versioning standart for
version numbers. Please visit L<http://semver.org/> to find out all about this
great thing.

=head1 CONTRIBUTORS

=over 4

=item * Sergey Romanov (SROMANOV)

=back

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
