#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
#---------------------------------------------------------------------
package Util;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  6 Oct 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Utilities for testing Dist-Zilla-Plugin-Git
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Cwd qw(cwd);
use File::Copy::Recursive qw(dircopy);
use File::pushd qw(pushd tempd);
use Git::Wrapper ();
use Path::Tiny qw(path);
use Test::DZil qw(Builder);
use Test::More;
use version 0.80 ();

our ($base_dir, $base_dir_pushed, $dist_dir, $git_dir, $git, $zilla);

use Exporter ();
our @ISA    = qw(Exporter);
our @EXPORT = qw($base_dir $git_dir $git $zilla
                 append_and_add append_to_file chdir_original_cwd
                 clean_environment init_repo init_test keep_tempdir
                 new_zilla_from_repo
                 skip_unless_git_version slurp_text_file
                 zilla_log_is);
our @EXPORT_OK = qw($dist_dir zilla_version);

my $original_cwd;

BEGIN {
  # Change back to the original directory when shutting down,
  # to avoid problems with cleaning up tmpdirs.
  $original_cwd = path('.')->absolute;
  # we chdir around so make @INC absolute
  @INC = map {; ref($_) ? $_ : path($_)->absolute->stringify } @INC;
}

END { chdir $original_cwd if $original_cwd }

#=====================================================================
sub append_and_add
{
  my $fn = $_[0];

  &append_to_file;

  $git->add("$fn");
} # end append_and_add

#---------------------------------------------------------------------
sub append_to_file {
  my $file = shift;

  my $fh = $git_dir->child($file)->opena_utf8;
  print $fh @_;
  close $fh;
}

#---------------------------------------------------------------------
sub chdir_original_cwd {
  chdir $original_cwd or die "Can't chdir $original_cwd: $!";
}

#---------------------------------------------------------------------
# Internal function shared by clean_environment & init_test

sub _clean_environment
{
  my $homedir = shift;

  delete $ENV{V}; # In case we're being released with a manual version
  delete $ENV{$_} for grep /^G(?:IT|PG)_/i, keys %ENV;

  $ENV{HOME} = $ENV{GNUPGHOME} = $homedir;
  $ENV{GIT_CONFIG_NOSYSTEM} = 1; # Don't read /etc/gitconfig
} # end _clean_environment

#---------------------------------------------------------------------
# Create a mock home directory & clear the environment

sub clean_environment
{
  my $tempdir = Path::Tiny->tempdir( CLEANUP => 1 );

  _clean_environment($tempdir->stringify);

  $tempdir;            # Object must remain in scope until you're done
} # end clean_environment

#---------------------------------------------------------------------
sub init_test
{
  my %opt = @_;

  $dist_dir = path('.')->absolute; # root of the distribution

  # Make a new directory so we don't affect the source repo:
  $base_dir_pushed = Path::Tiny->tempdir;
  $base_dir = $base_dir_pushed->absolute;

  # Mock HOME to keep user's global Git config from causing problems:
  my $homedir = $base_dir->child('home')->stringify;
  mkdir($homedir) or die "Failed to create $homedir: $!";
  _clean_environment($homedir);

  # Create the test repo:
  $git_dir = $base_dir->child('repo');
  $git_dir->mkpath;

  dircopy($dist_dir->child(corpus => $opt{corpus}), $git_dir)
      if defined $opt{corpus};

  if (my $files = $opt{add_files}) {
    while (my ($name, $content) = each %$files) {
      my $fn = $git_dir->child($name);
      $fn->parent->mkpath;
      $fn->spew_utf8( $content );
    }
  } # end if add_files

  $git = init_repo($git_dir);
} # end init_test

#---------------------------------------------------------------------
# Init a Git repo and set defaults.
# Returns a Git::Wrapper for the new repo.
# If @initial_files are supplied, also does add -f and commits.

sub init_repo
{
  my ($git_dir, @initial_files) = @_;

  {
    my $pushd = pushd($git_dir);
    system qw(git init --quiet) and die "Can't initialize repo in $git_dir";
  }

  my $git = Git::Wrapper->new("$git_dir");

  $git->config( 'push.default' => 'matching' ); # compatibility with Git 1.8
  $git->config( 'user.name'  => 'dzp-git test' );
  $git->config( 'user.email' => 'dzp-git@test' );

  # If core.autocrlf is true, then git add may hang on Windows.
  # This is probably a bug in Git::Wrapper, but a workaround is to set
  # autocrlf to false.  It seems to be caused by these warning messages
  # (from git version 1.8.5.2.msysgit.0):
  #   warning: LF will be replaced by CRLF in .gitignore.
  #   The file will have its original line endings in your working directory.
  $git->config( 'core.autocrlf' => 'false' );

  if (@initial_files) {
    # Don't use --force, because only -f works before git 1.5.6
    $git->add(-f => @initial_files);
    $git->commit( { message => 'initial commit' } );
  }

  $git;
} # end init_repo

#---------------------------------------------------------------------
sub keep_tempdir
{
  $base_dir_pushed->preserve;
  print "Git files are in $git_dir\n";
} # end keep_tempdir

#---------------------------------------------------------------------
sub new_zilla_from_repo
{
  $zilla = Builder->from_config({dist_root => $git_dir}, @_);
} # end zilla_from_repo

#---------------------------------------------------------------------
our $git_version;

sub skip_unless_git_version
{
  my $need_version = shift;

  $git_version = version->parse(
    Git::Wrapper->new('.')->version =~ m[^( \d+ (?: \. \d+ )+ )]x
  ) unless defined $git_version;

  if ( $git_version < version->parse($need_version) ) {
    my $why = "git $need_version or later required, you have $git_version";
    if (my $tests = shift) { skip $why, $tests     } # skip some
    else                   { plan skip_all => $why } # skip all
  } # end if we don't have the required version
} # end skip_unless_git_version

#---------------------------------------------------------------------
sub slurp_text_file
{
  my ($filename) = @_;

  return scalar do {
    local $/;
    # Don't use Path::Tiny's slurp_utf8 because it doesn't do
    # CRLF translation on Windows.
    if (open my $fh, '<:utf8', path( $zilla->tempdir )->child( $filename )) {
      <$fh>;
    } else {
      diag("Unable to open $filename: $!");
      undef;
    }
  };
} # end slurp_text_file

#---------------------------------------------------------------------
sub zilla_log_is
{
  my ($matching, $expected, $name) = @_;

  $name //= "log messages for $matching";

  $matching = qr /^\Q[$matching]\E/ unless ref $matching;

  my $got = join("\n", grep { /$matching/ } @{ $zilla->log_messages });
  $got =~ s/\s*\z/\n/;

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is( $got, $expected, $name);

  $zilla->clear_log_events;
}

#---------------------------------------------------------------------
sub zilla_version
{
  my $pushd = pushd($zilla->root); # Must be in the correct directory
  my $version = $zilla->version;
  return $version;
} # end zilla_version

#=====================================================================
# Package Return Value:

1;

__END__
