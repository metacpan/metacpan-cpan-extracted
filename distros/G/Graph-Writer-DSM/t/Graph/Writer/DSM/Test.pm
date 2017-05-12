package t::Graph::Writer::DSM::Test;
use base qw(Test::Class);
use Test::TempDir::Tiny;
use File::Path qw(rmtree);

INIT { Test::Class->runtests }

our $TEMP_DIR;
our $OLDPWD;

sub startup : Test(startup) {
  $OLDPWD = $ENV{PWD};
  $TEMP_DIR = tempdir;
  chdir $TEMP_DIR;
}

sub shutdown : Test(shutdown) {
  chdir $OLDPWD;
}

use Module::Install::Can;
sub can_run {
  Module::Install::Can->can_run($_[1]);
}

1;
