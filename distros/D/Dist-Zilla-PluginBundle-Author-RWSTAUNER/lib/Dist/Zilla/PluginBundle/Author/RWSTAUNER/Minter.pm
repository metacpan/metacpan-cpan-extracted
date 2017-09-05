# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-PluginBundle-Author-RWSTAUNER
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Author::RWSTAUNER::Minter;
our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: RWSTAUNER's Dist::Zilla config for minting
$Dist::Zilla::PluginBundle::Author::RWSTAUNER::Minter::VERSION = '6.002';
use Moose;
use MooseX::AttributeShortcuts;
use Git::Wrapper;
use Data::Section -setup;

with qw(
  Dist::Zilla::Role::PluginBundle::Easy
);

has pause_id => (
  is         => 'ro',
  default    => sub { ((ref($_[0]) || $_[0]) =~ /Author::([A-Z]+)/)[0] },
);

has _git => (
  is         => 'lazy',
  default    => sub { Git::Wrapper->new('.') },
);

sub git_config {
  my ($self, $key) = @_;
  return ($self->_git->config($key))[0];
}

foreach my $attr ( qw( name email ) ){
  has "git_$attr" => (
    is         => 'lazy',
    default    => sub { $_[0]->git_config("user.$attr") },
  );
}

has github_user => (
  is         => 'lazy',
  default    => sub { $_[0]->git_config("github.user") },
);

around bundle_config => sub {
  my ($orig, $self, @args) = @_;
  my @plugins = $self->$orig(@args);

  # remove bundle prefix since dzil looks this one up by name
  $_->[0] =~ s/.+?\/(:DefaultModuleMaker)/$1/ for @plugins;

  return @plugins;
};

sub configure {
  my ($self) = @_;

  $self->add_plugins(
    [ TemplateModule => ':DefaultModuleMaker', { template => 'Module.template' } ],

    [
      'Git::Init' => $self->github_user ? {
        remote => 'origin git@github.com:' . $self->github_user . '/%N.git',
        config => [
          'branch.master.remote origin',
          'branch.master.merge  refs/heads/master',
        ],
      } : {}
    ],

    #'GitHub::Create',

    [
      'Run::AfterMint' => {
        run => [
          # create the t/ directory so that it's already there
          # when i try to create a file beneath
          '%x -e "mkdir(shift(@ARGV))" %d%pt',
        ],
      },
    ],
  );

  $self->generate_files( $self->merged_section_data );
  $self->generate_mailmap;
}

sub generate_files {
  my ($self, $files) = @_;
  while( my ($name, $content) = each %$files ){
    $content = $$content;
    # GenerateFile will append a new line
    $content =~ s/\n+\z//;
    $self->add_plugins(
      [
        GenerateFile => "Generate-$name" => {
          filename    => $name,
          is_template => 1,
          content     => $content,
        }
      ],
    );
  }
}

sub generate_mailmap {
  my ($self) = @_;
  $self->generate_files({
    '.mailmap' => \sprintf '%s <%s@cpan.org> <%s>',
      $self->git_name, lc($self->pause_id), $self->git_email,
  });
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS RWSTAUNER's PluginBundle

=head1 NAME

Dist::Zilla::PluginBundle::Author::RWSTAUNER::Minter - RWSTAUNER's Dist::Zilla config for minting

=head1 VERSION

version 6.002

=head1 SYNOPSIS

  ; profile.ini

  [@Author::RWSTAUNER::Minter]

=head1 DESCRIPTION

Configure L<Dist::Zilla> to mint a new dist.

=for Pod::Coverage configure
git_config
generate_files
generate_mailmap

=head1 ROUGHLY EQUIVALENT

This bundle is roughly equivalent to the following (generated) F<profile.ini>:

  [TemplateModule / :DefaultModuleMaker]
  template = Module.template

  [Git::Init]
  config = branch.master.remote origin
  config = branch.master.merge  refs/heads/master
  remote = origin git@github.com:rwstauner/%N.git

  [Run::AfterMint]
  run = %x -e "mkdir(shift(@ARGV))" %d%pt

  [GenerateFile / Generate-Changes]
  content     = Revision history for {{$dist->name}}
  content     = {{ '{{$NEXT}}' }}
  content     =   - Initial release
  filename    = Changes
  is_template = 1

  [GenerateFile / Generate-README.mkdn]
  content     = # NAME
  content     = {{ (my $n = $dist->name) =~ s/-/::/g; $n }} - undef
  content     = # COPYRIGHT AND LICENSE
  content     = This software is copyright (c) {{ (localtime)[5]+1900 }} by {{ $dist->copyright_holder }}.
  content     = This is free software; you can redistribute it and/or modify it under
  content     = the same terms as the Perl 5 programming language system itself.
  filename    = README.mkdn
  is_template = 1

  [GenerateFile / Generate-.gitignore]
  content     = /{{$dist->name}}*
  content     = /.build
  content     = /cover_db/
  content     = /nytprof*
  content     = /tags
  filename    = .gitignore
  is_template = 1

  [GenerateFile / Generate-dist.ini]
  content     = {{
  content     =   $license = ref $dist->license;
  content     =   if ( $license =~ /^Software::License::(.+)$/ ) {
  content     =     $license = $1;
  content     =   } else {
  content     =     $license = "=$license";
  content     =   }
  content     =   $authors = join( "\n", map { "author   = $_" } @{ $dist->authors } );
  content     =   $copyright_year = (localtime)[5] + 1900;
  content     =   '';
  content     = }}name     = {{ $dist->name }}
  content     = {{ $authors }}
  content     = license  = {{ $license }}
  content     = copyright_holder = {{ join( ', ', map { (/^(.+) <.+>/)[0] }@{ $dist->authors } ) }}
  content     = copyright_year   = {{ $copyright_year }}
  content     = [@Author::RWSTAUNER]
  filename    = dist.ini
  is_template = 1

  [GenerateFile / Generate-LICENSE]
  content     = This is free software; you can redistribute it and/or modify it under
  content     = the same terms as the Perl 5 programming language system itself.
  filename    = LICENSE
  is_template = 1

  [GenerateFile / Generate-.mailmap]
  content     = Randy Stauner <rwstauner@cpan.org> <randy@magnificent-tears.com>
  filename    = .mailmap
  is_template = 1

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::MintingProfile::Author::RWSTAUNER>

=item *

L<Dist::Zilla::Role::PluginBundle::Easy>

=back

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ .gitignore ]__
/{{$dist->name}}*
/.build
/cover_db/
/nytprof*
/tags
__[ dist.ini ]__
{{
  $license = ref $dist->license;
  if ( $license =~ /^Software::License::(.+)$/ ) {
    $license = $1;
  } else {
    $license = "=$license";
  }

  $authors = join( "\n", map { "author   = $_" } @{ $dist->authors } );
  $copyright_year = (localtime)[5] + 1900;
  '';
}}name     = {{ $dist->name }}
{{ $authors }}
license  = {{ $license }}
copyright_holder = {{ join( ', ', map { (/^(.+) <.+>/)[0] }@{ $dist->authors } ) }}
copyright_year   = {{ $copyright_year }}

[@Author::RWSTAUNER]
__[ Changes ]__
Revision history for {{$dist->name}}

{{ '{{$NEXT}}' }}

  - Initial release
__[ LICENSE ]__

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

__[ README.mkdn ]__
# NAME

{{ (my $n = $dist->name) =~ s/-/::/g; $n }} - undef

# COPYRIGHT AND LICENSE

This software is copyright (c) {{ (localtime)[5]+1900 }} by {{ $dist->copyright_holder }}.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
