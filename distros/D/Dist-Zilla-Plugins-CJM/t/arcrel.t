#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More 0.88 tests => 6; # done_testing

use Test::DZil 'Builder';

sub make_ini
{
  my $ini = <<'END START';
name     = DZT-Sample
abstract = Sample DZ Dist
version  = 0.001
author   = E. Xavier Ample <example@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample
END START

  $ini . join('', map { "$_\n" } @_);
} # end make_ini

sub new_tzil
{
  my ($archiveConfig, $copy_archives) = @_;

  Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => make_ini(
          '[GatherDir]',
          '[ArchiveRelease]',
          @$archiveConfig,
        ),
      },
      ($copy_archives
       ? (also_copy => { 'corpus/archives' => $copy_archives })
       : ()),
    },
  );
} # end new_tzil

{
  my $tzil = new_tzil([], 'source/releases');

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_deeply(
    [ sort @files ],
    [ sort(qw(dist.ini README lib/DZT/Sample.pm lib/DZT/Manual.pod t/basic.t)),
    ],
    "ArchiveRelease prunes default releases directory",
  );
}


{
  my $tzil = new_tzil(['directory = cjm_releases'], 'source/cjm_releases');

  $tzil->build;

  my @files = map {; $_->name } @{ $tzil->files };

  is_deeply(
    [ sort @files ],
    [ sort(qw(dist.ini README lib/DZT/Sample.pm lib/DZT/Manual.pod t/basic.t)),
    ],
    "ArchiveRelease prunes non-standard releases directory",
  );
}


{
  my $tzil = new_tzil([], 'source/releases');

  $tzil->release;

  my $tarball = $tzil->root->file('releases/DZT-Sample-0.001.tar.gz');
  ok(-e $tarball, 'archived tarball');
  is($tarball->stat->mode & 0777, 0444, 'tarball is read-only');
  ok((not -e $tzil->root->file('DZT-Sample-0.001.tar.gz')),
     'tarball was moved');
}

{
  require File::HomeDir;

  my $tzil = new_tzil(['directory = ~/some/dir']);

  my $arcrel = $tzil->plugins_with(-Releaser)->[0];

  is($arcrel->directory,
     Path::Class::dir(File::HomeDir->my_home, qw(some dir)),
     '~ expansion');
}

done_testing;
