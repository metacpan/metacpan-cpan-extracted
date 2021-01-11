#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;

use Path::Tiny qw(path);
use Test::DZil;

###############################################################################
subtest 'With no minimum Perl specified' => sub {
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        path(qw( source dist.ini )) => simple_ini(
          [ 'EnsureMinimumPerl' ],
          [ 'FakeRelease' ],
        ),
      },
    },
  );

  eval { $tzil->release };
  my $err = $@;
  ok $err, 'Failed to release';
  like $err, qr/EnsureMinimumPerl/, '... due to missing minimum Perl version';
};

###############################################################################
subtest 'With  minimum Perl specified' => sub {
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        path(qw( source dist.ini )) => simple_ini(
          [ 'EnsureMinimumPerl' ],
          [ 'Prereqs', { perl => 5.008 } ],
          [ 'FakeRelease' ],
        ),
      },
    },
  );

  eval { $tzil->release };
  my $err = $@;
  ok !$err, 'Released; we have a minimum Perl version specified';
};

###############################################################################
done_testing();
