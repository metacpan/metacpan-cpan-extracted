#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dist::Zilla::Plugin::Git::GatherDir;
# ABSTRACT: Gather all tracked files in a Git working directory

our $VERSION = '2.042';

use Moose;
extends 'Dist::Zilla::Plugin::GatherDir' => { -version => 4.200016 }; # exclude_match

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod     [Git::GatherDir]
#pod     root = .                     ; this is the default
#pod     prefix =                     ; this is the default
#pod     include_dotfiles = 0         ; this is the default
#pod     include_untracked = 0        ; this is the default
#pod     exclude_filename = dir/skip  ; there is no default
#pod     exclude_match = ^local_      ; there is no default
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a trivial variant of the L<GatherDir|Dist::Zilla::Plugin::GatherDir>
#pod plugin.  It looks in the directory named in the L</root> attribute and adds all
#pod the Git tracked files it finds there (as determined by C<git ls-files>).  If the
#pod root begins with a tilde, the tilde is replaced with the current user's home
#pod directory according to L<File::HomeDir>.
#pod
#pod Most users just need:
#pod
#pod   [Git::GatherDir]
#pod
#pod ...and this will pick up all tracked files from the current directory into the
#pod dist.  You can use it multiple times, as you can any other plugin, by providing
#pod a plugin name.  For example, if you want to include external specification
#pod files into a subdir of your dist, you might write:
#pod
#pod   [Git::GatherDir]
#pod   ; this plugin needs no config and gathers most of your files
#pod
#pod   [Git::GatherDir / SpecFiles]
#pod   ; this plugin gets all tracked files in the root dir and adds them under ./spec
#pod   root   = ~/projects/my-project/spec
#pod   prefix = spec
#pod
#pod =cut

use List::Util 1.45 qw(uniq);
use MooseX::Types::Moose qw(Bool);

use namespace::autoclean;

#pod =attr root
#pod
#pod This is the directory in which to look for files.  If not given, it defaults to
#pod the dist root -- generally, the place where your F<dist.ini> or other
#pod configuration file is located.  It may begin with C<~> (or C<~user>)
#pod to mean your (or some other user's) home directory.  If a relative path,
#pod it's relative to the dist root.  It does not need to be the root of a
#pod Git repository, but it must be inside a repository.
#pod
#pod =attr prefix
#pod
#pod This parameter can be set to gather all the files found under a common
#pod directory.  See the L<description|DESCRIPTION> above for an example.
#pod
#pod =attr include_dotfiles
#pod
#pod By default, files will not be included if they begin with a dot.  This goes
#pod both for files and for directories relative to the C<root>.
#pod
#pod In almost all cases, the default value (false) is correct.
#pod
#pod =attr include_untracked
#pod
#pod By default, files not tracked by Git will not be gathered.  If this is
#pod set to a true value, then untracked files not covered by a Git ignore
#pod pattern (i.e. those reported by C<git ls-files -o --exclude-standard>)
#pod are also gathered (and you'll probably want to use
#pod L<Git::Check|Dist::Zilla::Plugin::Git::Check> to ensure all files are
#pod checked in before a release).
#pod
#pod C<include_untracked> requires at least Git 1.5.4, but you should
#pod probably not use it if your Git is older than 1.6.5.2.  Versions
#pod before that would not list files matched by your F<.gitignore>, even
#pod if they were already being tracked by Git (which means they will not
#pod be gathered, even though they should be).  Whether that is a problem
#pod depends on the contents of your exclude files (including the global
#pod one, if any).
#pod
#pod =attr follow_symlinks
#pod
#pod Git::GatherDir does not honor GatherDir's
#pod L<follow_symlinks|Dist::Zilla::Plugin::GatherDir/follow_symlinks>
#pod option.  While the attribute exists (because Git::GatherDir is a
#pod subclass), setting it has no effect.
#pod
#pod Directories that are symlinks will not be gathered.  Instead, you'll
#pod get a message saying C<WARNING: %s is symlink to directory, skipping it>.
#pod To suppress the warning, add that directory to C<exclude_filename> or
#pod C<exclude_match>.  To gather the files in the symlinked directory, use
#pod a second instance of GatherDir or Git::GatherDir with appropriate
#pod C<root> and C<prefix> options.
#pod
#pod Files which are symlinks are always gathered.
#pod
#pod =attr exclude_filename
#pod
#pod To exclude certain files from being gathered, use the C<exclude_filename>
#pod option. This may be used multiple times to specify multiple files to exclude.
#pod
#pod =attr exclude_match
#pod
#pod This is just like C<exclude_filename> but provides a regular expression
#pod pattern.  Files matching the pattern are not gathered.  This may be used
#pod multiple times to specify multiple patterns to exclude.
#pod
#pod =cut

has include_untracked => (
  is  => 'ro',
  isa => Bool,
  default => 0,
);

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        include_untracked => $self->include_untracked ? 1 : 0,
    };

    return $config;
};

override gather_files => sub {
  my ($self) = @_;

  require Git::Wrapper;
  require Path::Tiny;

  my $root = "" . $self->root;
  # Convert ~ to home directory:
  if ($root =~ /^~/) {
    require File::HomeDir;
    File::HomeDir->VERSION(0.81);

    $root =~ s/^~(\w+)/ File::HomeDir->users_home("$1") /e;
    $root =~ s/^~/      File::HomeDir->my_home /e;
  } # end if $root begins with ~
  $root = Path::Tiny::path($root)->absolute($self->zilla->root->absolute);

  # Prepare to gather files
  my $git = Git::Wrapper->new($root->stringify);

  my @opts;
  @opts = qw(--cached --others --exclude-standard) if $self->include_untracked;

  my $exclude_regex = qr/\000/;
  $exclude_regex = qr/$exclude_regex|$_/
    for (@{ $self->exclude_match });

  my %is_excluded = map {; $_ => 1 } @{ $self->exclude_filename };

  my $prefix = $self->prefix;

  # Loop over files reported by git ls-files
  for my $filename (uniq $git->ls_files(@opts)) {
    # $file is a Path::Tiny relative to $root
    my $file = Path::Tiny::path($filename);

    $self->log_debug("considering $file");

    # Exclusion tests
    unless ($self->include_dotfiles) {
      next if grep { /^\./ } split q{/}, $file->stringify;
    }

    next if $file =~ $exclude_regex;
    next if $is_excluded{ $file };

    # DZil can't gather directory symlinks
    my $path = $root->child($file);

    if (-d $path) {
      $self->log("WARNING: $file is symlink to directory, skipping it");
      next;
    }

    # Gather the file
    my $fileobj = $self->_file_from_filename($path->stringify);

    $file = Path::Tiny::path($prefix, $file) if length $prefix;

    $fileobj->name($file->stringify);
    $self->add_file($fileobj);
    $self->log_debug("gathered $file");
  }

  return;
};


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::GatherDir - Gather all tracked files in a Git working directory

=head1 VERSION

version 2.042

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::GatherDir]
    root = .                     ; this is the default
    prefix =                     ; this is the default
    include_dotfiles = 0         ; this is the default
    include_untracked = 0        ; this is the default
    exclude_filename = dir/skip  ; there is no default
    exclude_match = ^local_      ; there is no default

=head1 DESCRIPTION

This is a trivial variant of the L<GatherDir|Dist::Zilla::Plugin::GatherDir>
plugin.  It looks in the directory named in the L</root> attribute and adds all
the Git tracked files it finds there (as determined by C<git ls-files>).  If the
root begins with a tilde, the tilde is replaced with the current user's home
directory according to L<File::HomeDir>.

Most users just need:

  [Git::GatherDir]

...and this will pick up all tracked files from the current directory into the
dist.  You can use it multiple times, as you can any other plugin, by providing
a plugin name.  For example, if you want to include external specification
files into a subdir of your dist, you might write:

  [Git::GatherDir]
  ; this plugin needs no config and gathers most of your files

  [Git::GatherDir / SpecFiles]
  ; this plugin gets all tracked files in the root dir and adds them under ./spec
  root   = ~/projects/my-project/spec
  prefix = spec

=head1 ATTRIBUTES

=head2 root

This is the directory in which to look for files.  If not given, it defaults to
the dist root -- generally, the place where your F<dist.ini> or other
configuration file is located.  It may begin with C<~> (or C<~user>)
to mean your (or some other user's) home directory.  If a relative path,
it's relative to the dist root.  It does not need to be the root of a
Git repository, but it must be inside a repository.

=head2 prefix

This parameter can be set to gather all the files found under a common
directory.  See the L<description|DESCRIPTION> above for an example.

=head2 include_dotfiles

By default, files will not be included if they begin with a dot.  This goes
both for files and for directories relative to the C<root>.

In almost all cases, the default value (false) is correct.

=head2 include_untracked

By default, files not tracked by Git will not be gathered.  If this is
set to a true value, then untracked files not covered by a Git ignore
pattern (i.e. those reported by C<git ls-files -o --exclude-standard>)
are also gathered (and you'll probably want to use
L<Git::Check|Dist::Zilla::Plugin::Git::Check> to ensure all files are
checked in before a release).

C<include_untracked> requires at least Git 1.5.4, but you should
probably not use it if your Git is older than 1.6.5.2.  Versions
before that would not list files matched by your F<.gitignore>, even
if they were already being tracked by Git (which means they will not
be gathered, even though they should be).  Whether that is a problem
depends on the contents of your exclude files (including the global
one, if any).

=head2 follow_symlinks

Git::GatherDir does not honor GatherDir's
L<follow_symlinks|Dist::Zilla::Plugin::GatherDir/follow_symlinks>
option.  While the attribute exists (because Git::GatherDir is a
subclass), setting it has no effect.

Directories that are symlinks will not be gathered.  Instead, you'll
get a message saying C<WARNING: %s is symlink to directory, skipping it>.
To suppress the warning, add that directory to C<exclude_filename> or
C<exclude_match>.  To gather the files in the symlinked directory, use
a second instance of GatherDir or Git::GatherDir with appropriate
C<root> and C<prefix> options.

Files which are symlinks are always gathered.

=head2 exclude_filename

To exclude certain files from being gathered, use the C<exclude_filename>
option. This may be used multiple times to specify multiple files to exclude.

=head2 exclude_match

This is just like C<exclude_filename> but provides a regular expression
pattern.  Files matching the pattern are not gathered.  This may be used
multiple times to specify multiple patterns to exclude.

=for Pod::Coverage gather_dir
    gather_files

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
