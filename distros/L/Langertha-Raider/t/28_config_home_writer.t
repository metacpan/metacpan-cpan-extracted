#!/usr/bin/env perl
# ABSTRACT: Config->update_home, the atomic writer of ~/.raider/config.yml (k132)

use strict;
use warnings;
use utf8;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
my $home = path( isolate_home() );
use Langertha::Raider::Config;

clear_engine_env();

{
  package Test::Config::DumpFails;
  use Moose;
  extends 'Langertha::Raider::Config';
  sub _dump { die "dump failed\n" }
  __PACKAGE__->meta->make_immutable;
}

my $dir  = $home->child('.raider');
my $file = $dir->child('config.yml');
my $bak  = $dir->child('config.yml.bak');

sub config { Langertha::Raider::Config->new( root => tempdir( CLEANUP => 1 ), @_ ) }
sub mode   { sprintf '%04o', $_[0]->stat->mode & 07777 }
sub load   { YAML::PP->new->load_string( $_[0]->slurp_utf8 ) }

subtest 'creates dir and file with private modes' => sub {
  ok !-e $dir, 'no ~/.raider yet';
  ok config()->update_home( sub { $_[0]{default} = { model => 'm1', api_key => 'sk-x' }; 1 } ), 'wrote';
  is mode($dir),  '0700', 'dir 0700';
  is mode($file), '0600', 'file 0600';
  is load($file), { default => { model => 'm1', api_key => 'sk-x' } }, 'content';
  ok !-e $bak, 'no backup when there was no previous file';
  is [ map { $_->basename } $dir->children ], ['config.yml'], 'no temp file left';
};

subtest 'update keeps other keys and backs up the previous file' => sub {
  my $before = $file->slurp_utf8;
  my $c = config();
  ok $c->update_home( sub { $_[0]{skills} = ['claude']; 1 } ), 'wrote';
  is load($file), { default => { model => 'm1', api_key => 'sk-x' }, skills => ['claude'] }, 'merged, old keys kept';
  is $bak->slurp_utf8, $before, 'backup is the previous content';
  is mode($bak), '0600', 'backup 0600';

  my $second = $file->slurp_utf8;
  $c->update_home( sub { $_[0]{engine} = 'openai'; 1 } );
  is $bak->slurp_utf8, $second, 'one generation: backup is replaced';
  is mode($file), '0600', 'still 0600';
};

subtest 'false from the callback writes nothing' => sub {
  my ( $before, $bak_before ) = ( $file->slurp_utf8, $bak->slurp_utf8 );
  ok !config()->update_home( sub { 0 } ), 'returns false';
  is $file->slurp_utf8, $before, 'file untouched';
  is $bak->slurp_utf8, $bak_before, 'backup untouched';
};

subtest 'caches are dropped after a write' => sub {
  my $c = config();
  $c->update_home( sub { $_[0]{default}{model} = 'm2'; 1 } );
  ok $c->uses_home, 'home now read as a layer';
  is $c->home_data->{default}{model}, 'm2', 'home_data reflects the write';
};

subtest 'a failing write leaves the file, its backup and the dir clean' => sub {
  my ( $before, $bak_before ) = ( $file->slurp_utf8, $bak->slurp_utf8 );
  my $c = Test::Config::DumpFails->new( root => tempdir( CLEANUP => 1 ) );
  like dies { $c->update_home( sub { $_[0]{x} = 1; 1 } ) }, qr/dump failed/, 'dies';
  is $file->slurp_utf8, $before, 'file untouched';
  is $bak->slurp_utf8, $bak_before, 'backup untouched';
  is [ sort map { $_->basename } $dir->children ], [ 'config.yml', 'config.yml.bak' ], 'no temp file left';
};

subtest 'a broken existing file is refused and left alone' => sub {
  my $broken = "default: [unclosed\n";
  $file->spew_utf8($broken);
  my $bak_before = $bak->slurp_utf8;
  like dies { config()->update_home( sub { $_[0]{x} = 1; 1 } ) }, qr/Cannot parse \Q$file\E/, 'croaks';
  is $file->slurp_utf8, $broken, 'file untouched';
  is $bak->slurp_utf8, $bak_before, 'backup untouched';

  $file->spew_utf8("- a\n- b\n");
  like dies { config()->update_home( sub { 1 } ) }, qr/top level must be a mapping/, 'non-mapping refused';
  is $file->slurp_utf8, "- a\n- b\n", 'file untouched';
};

subtest 'home == project root: the same file' => sub {
  $file->spew_utf8("default:\n  model: m1\n");
  my $c = Langertha::Raider::Config->new( root => $home->stringify );
  is $c->file->realpath, $file->realpath, 'the project file is the home file';
  ok !$c->uses_home, 'no separate home layer';
  ok $c->update_home( sub { $_[0]{skills} = ['a']; 1 } ), 'wrote';
  is $c->data->{skills}, ['a'], 'project data sees the write';
  ok $c->add_skills('b'), 'project writer keeps working on the same file';
  is load($file), { default => { model => 'm1' }, skills => [ 'a', 'b' ] }, 'one file, both writes';
};

subtest 'no home at all' => sub {
  {
    package Test::NoHome;
    use parent -norequire, 'Langertha::Raider::Home';
    sub home_base { return }
    package Test::Config::NoHome;
    use Moose;
    extends 'Langertha::Raider::Config';
    sub home_class { 'Test::NoHome' }
    __PACKAGE__->meta->make_immutable;
  }
  like dies { Test::Config::NoHome->new( root => tempdir( CLEANUP => 1 ) )->update_home( sub { 1 } ) },
    qr/no home directory/, 'croaks';
};

done_testing;
