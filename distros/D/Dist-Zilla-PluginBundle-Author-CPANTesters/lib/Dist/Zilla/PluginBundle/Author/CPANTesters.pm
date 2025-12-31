package Dist::Zilla::PluginBundle::Author::CPANTesters;
our $VERSION = '0.003';
# ABSTRACT: Dist::Zilla plugin bundle for CPAN Testers applications

#pod =head1 SYNOPSIS
#pod
#pod   # In your dist.ini
#pod   [@Author::CPANTesters]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This bundle does the standard CPAN Testers build process.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Dist::Zilla>, L<Dist::Zilla::Role::PluginBundle::Easy>
#pod
#pod =cut

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';
use namespace::autoclean;

sub configure {
  my $self = shift;
  $self->add_bundle('Filter', {
    -bundle => '@Basic',
    -remove => [qw( GatherDir Readme )],
  });

  $self->add_plugins(
    'Readme::Brief',
    [
      'ReadmeAnyFromPod', {
        location => 'root',
        filename => 'README.mkdn',
        type => 'markdown',
      },
    ],
    [
      'PodWeaver', {
        replacer => 'replace_with_comment',
        post_code_replacer => 'replace_with_nothing', 
      },
    ],
    'RewriteVersion',
    'CPANFile',
    'MetaJSON',
    'MetaProvides::Package',
    [
      'MetaNoIndex', {
        directory => [qw( t xt inc share eg examples )],
      },
    ],
    'Git::Contributors',
    'Test::ReportPrereqs',
    'Test::Compile',
    [
      'Git::GatherDir', {
        include_dotfiles => 1,
        prune_directory => [qw( ^eg )],
        exclude_match => [
          # Exclude dotfiles in the root directory
          '^\.[^/]+$',
        ],
        exclude_filename => [
          # Exclude generated root content, which is included by the various plugins
          # Without this, we get an error about duplicate content
          'cpanfile',
          'META.json',
          'LICENSE',
          'README',
          'README.mkdn',
          'Makefile.PL',
        ],
      },
    ],

    [
      # Copy generated content to the repository root so users without Dist::Zilla
      # can use it
      'CopyFilesFromBuild', {
        copy => [qw( cpanfile META.json LICENSE Makefile.PL )],
      },
    ],

    [ 'CheckChangesHasContent', => { changelog => 'CHANGES' } ],

    # Automatically commit these files during release
    [
      'Git::Check' => {
        allow_dirty_match => [qw( README.* .*[.]PL )],
        allow_dirty => [qw( cpanfile LICENSE CHANGES META.json )],
      },
    ],

    # Automatically commit with release version and changelog
    [
      'Git::Commit' => 'Commit_Dirty_Files', {
        changelog => 'CHANGES',
        commit_msg => 'release v%v%n%n%c',
        allow_dirty_match => [qw( README.* .*[.]PL )],
        allow_dirty => [qw( cpanfile LICENSE CHANGES META.json )],
        add_files_in => '.',
      },
    ],
    [
      'Git::Tag' => {
        changelog => 'CHANGES',
        tag_message => '%N v%v - %{yyyy-MM-dd}d%n%n%c', # Tag annotations show up in github release list
      },
    ],

    # NextRelease acts *during* pre-release to write $VERSION and
    # timestamp to Changes and  *after* release to add a new 
    # section, so to act at the right time after release, it must actually
    # come after Commit_Dirty_Files but before Commit_Changes in the
    # dist.ini.  It will still act during pre-release as usual
    [ 'NextRelease' => { filename => 'CHANGES' } ],
    'BumpVersionAfterRelease',

    [
      'Git::Commit', 'Commit_Changes', {
        commit_msg => 'incrementing version after release',
        allow_dirty => [qw( CHANGES )],
        allow_dirty_match => [qw( ^bin/ ^lib/.*\.pm$ .*[.]PL )],
      },
    ],
    'Git::Push',

    [
      'Run::AfterRelease', 'clean up release dirs', {
        run => 'rm -rf %a %d',
      },
    ],
  );

  # XXX: How to add authordep Pod::Weaver::Section::Contributors?
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::Author::CPANTesters - Dist::Zilla plugin bundle for CPAN Testers applications

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # In your dist.ini
  [@Author::CPANTesters]

=head1 DESCRIPTION

This bundle does the standard CPAN Testers build process.

=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::Role::PluginBundle::Easy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
