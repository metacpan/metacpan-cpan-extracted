#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More 0.88 tests => 2; # done_testing

use Test::DZil 'Builder';

sub make_ini
{
  my $ini = <<'END START';
name     = DZT-Sample
author   = E. Xavier Ample <example@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample
abstract = Sample dist
END START

  $ini . join('', map { "$_\n" } @_);
} # end make_ini

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => make_ini(
          '[GatherDir]',
          '[VersionFromModule]',
        ),
      },
    },
  );

  $tzil->build;

  is($tzil->version, '0.04', "VersionFromModule found version",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/latin1' },
    {
      add_files => {
        'source/dist.ini' => make_ini(
          '[@Basic]',
          '[VersionFromModule]',
          (Dist::Zilla->VERSION < 5
           ? ()
           : "[Encoding]\nfilename = lib/EncTest.pm\nencoding = Latin-1"),
        ),
      },
    },
  );

  $tzil->build;

  is($tzil->version, '0.357', "Handled Latin-1 encoded module",
  );
}

done_testing;
