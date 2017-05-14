#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Role::Git::DirtyFiles;
# ABSTRACT: Provide the allow_dirty & changelog attributes

our $VERSION = '2.042';

use Moose::Role;
use MooseX::Types::Moose qw{ Any ArrayRef Str RegexpRef };
use MooseX::Types::Path::Tiny 0.010 qw{ Paths to_Paths };
use Moose::Util::TypeConstraints;

use namespace::autoclean;
use Path::Tiny 0.048 qw(); # subsumes
use Try::Tiny;

requires qw(log_fatal repo_root zilla);

# -- attributes

#pod =attr allow_dirty
#pod
#pod A list of paths that are allowed to be dirty in the git checkout.
#pod Defaults to C<dist.ini> and the changelog (as defined per the
#pod C<changelog> attribute.
#pod
#pod If your C<repo_root> is not the default (C<.>), then these pathnames
#pod are relative to Dist::Zilla's root directory, not the Git root directory.
#pod
#pod =attr allow_dirty_match
#pod
#pod A list of regular expressions that match paths allowed to be dirty in
#pod the git checkout.  This is combined with C<allow_dirty>.  Defaults to
#pod the empty list.
#pod
#pod The paths being matched are relative to the Git root directory, even
#pod if your C<repo_root> is not the default (C<.>).
#pod
#pod =attr changelog
#pod
#pod The name of the changelog. Defaults to C<Changes>.
#pod
#pod =cut

{
  # We specifically allow the empty string to represent the empty list.
  # Otherwise, there'd be no way to specify an empty list in an INI file.
  my $type = subtype as Paths;
  coerce($type,
    from ArrayRef, via { to_Paths( [ grep { length } @$_ ] ) },
    from Any, via { length($_) ? to_Paths($_) : [] },
  );

  has allow_dirty => (
    is => 'ro', lazy => 1,
    isa     => $type,
    coerce  => 1,
    builder => '_build_allow_dirty',
  );
}

has changelog => ( is => 'ro', isa=>Str, default => 'Changes' );

{
  my $type = subtype as ArrayRef[RegexpRef];
  coerce $type, from ArrayRef[Str], via { [map { qr/$_/ } @$_] };
  has allow_dirty_match => (
    is => 'ro',
    lazy => 1,
    coerce => 1,
    isa => $type,
    default => sub { [] },
  );
}

around mvp_multivalue_args => sub {
  my ($orig, $self) = @_;

  my @start = $self->$orig;
  return (@start, 'allow_dirty', 'allow_dirty_match');
};

# -- builders & initializers

sub _build_allow_dirty { [ 'dist.ini', shift->changelog ] }

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        (map { $_ => [ sort @{ $self->$_ } ] } qw(allow_dirty allow_dirty_match)),
        changelog => $self->changelog,
    };

    return $config;
};

#pod =method list_dirty_files
#pod
#pod   my @dirty = $plugin->list_dirty_files($git, $listAllowed);
#pod
#pod This returns a list of the modified or deleted files in C<$git>,
#pod filtered against the C<allow_dirty> attribute.  If C<$listAllowed> is
#pod true, only allowed files are listed.  If it's false, only files that
#pod are not allowed to be dirty are listed.
#pod
#pod In scalar context, returns the number of dirty files.
#pod
#pod =cut

sub list_dirty_files
{
  my ($self, $git, $listAllowed) = @_;

  my $git_root  = $self->repo_root;
  my @filenames = @{ $self->allow_dirty };

  if ($git_root ne '.') {
    # Interpret allow_dirty relative to the dzil root
    my $dzil_root = Path::Tiny::path($self->zilla->root)->absolute->realpath;
    $git_root     = Path::Tiny::path($git_root)
                      ->absolute($dzil_root)
                      ->realpath;

    $self->log_fatal("Dzil root $dzil_root is not inside Git root $git_root")
        unless $git_root->subsumes($dzil_root);

    for my $fn (@filenames) {
      try {
        $fn = Path::Tiny::path($fn)
                ->absolute($dzil_root)
                ->realpath            # process ..
                ->relative($git_root)
                ->stringify;
      };
    }
  } # end if git root ne dzil root

  my $allowed = join '|', @{ $self->allow_dirty_match }, map { qr{^\Q$_\E$} } @filenames;

  $allowed = qr/(?!X)X/ if $allowed eq ''; # this cannot match anything

  return grep { /$allowed/ ? $listAllowed : !$listAllowed }
      $git->ls_files( { modified=>1, deleted=>1 } );
} # end list_dirty_files


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Git::DirtyFiles - Provide the allow_dirty & changelog attributes

=head1 VERSION

version 2.042

=head1 DESCRIPTION

This role is used within the git plugin to work with files that are
dirty in the local git checkout.

=head1 ATTRIBUTES

=head2 allow_dirty

A list of paths that are allowed to be dirty in the git checkout.
Defaults to C<dist.ini> and the changelog (as defined per the
C<changelog> attribute.

If your C<repo_root> is not the default (C<.>), then these pathnames
are relative to Dist::Zilla's root directory, not the Git root directory.

=head2 allow_dirty_match

A list of regular expressions that match paths allowed to be dirty in
the git checkout.  This is combined with C<allow_dirty>.  Defaults to
the empty list.

The paths being matched are relative to the Git root directory, even
if your C<repo_root> is not the default (C<.>).

=head2 changelog

The name of the changelog. Defaults to C<Changes>.

=head1 METHODS

=head2 list_dirty_files

  my @dirty = $plugin->list_dirty_files($git, $listAllowed);

This returns a list of the modified or deleted files in C<$git>,
filtered against the C<allow_dirty> attribute.  If C<$listAllowed> is
true, only allowed files are listed.  If it's false, only files that
are not allowed to be dirty are listed.

In scalar context, returns the number of dirty files.

=for Pod::Coverage mvp_multivalue_args

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git>
(or L<bug-Dist-Zilla-Plugin-Git@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
