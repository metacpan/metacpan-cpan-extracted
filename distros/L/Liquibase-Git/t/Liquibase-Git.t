#!/usr/bin/env perl

use strict;
use warnings;
use File::Temp qw/tempdir/;
use Test::More;

use_ok('Liquibase::Git');

my $lb = Liquibase::Git->new(
  username           => 'fake_user',
  password           => 'fake_password',
  git_changeset_file => 'changeset.xml',
  db                 => 'fake_db',
  hostname           => 'fake_dbhost.example.com',
  changelog_basedir  => tempdir(CLEANUP => 1),
  git_changeset_dir  => 'dbpatches/fake_db',
  build_id           => '2014-09-26-01',
  git_repo           => 'https://github.com/foo/bar.git',
  git_identifier     => 'f70eddd106aed1a3157587343eb4da293b890625',
  db_type            => 'postgresql',
);

isa_ok($lb, 'Liquibase::Git');

is $lb->username, 'fake_user', 'correct username';
is $lb->password, 'fake_password', 'correct password';
is $lb->db, 'fake_db', 'correct db';
is $lb->hostname, 'fake_dbhost.example.com', 'correct hostname';
is $lb->git_changeset_dir, 'dbpatches/fake_db', 'correct git changeset dir';
is $lb->git_changeset_file, 'changeset.xml', 'git_changeset_file is changeset.xml';


done_testing();

1;

