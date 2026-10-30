#!/usr/bin/env perl
# ABSTRACT: The one confinement shared by the file and the search tools (ADR 0023)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Langertha::Raider::PathConfine;

my $tmp   = Path::Tiny->tempdir->realpath;
my $root  = $tmp->child('root');
my $extra = $tmp->child('extra');
my $other = $tmp->child('other');
$_->mkpath for $root, $extra, $other;
$extra->child('f.txt')->spew('x');

subtest 'inside the root, outside it, and the sibling that shares a prefix' => sub {
  my $c = Langertha::Raider::PathConfine->new( root => "$root" );
  ok $c->allows("$root"), 'the root itself';
  ok $c->allows( $root->child('a/b.txt')->stringify ), 'below it';
  ok !$c->allows("$other"), 'a sibling';
  $tmp->child('root2')->mkpath;
  ok !$c->allows( $tmp->child('root2')->stringify ), 'a directory whose name starts like the root';
};

subtest 'additional directories' => sub {
  my $c = Langertha::Raider::PathConfine->new( root => "$root", extra_roots => [ "$extra", "$tmp/missing", undef ] );
  ok $c->allows( $extra->child('f.txt')->stringify ), 'inside an additional directory';
  ok !$c->allows("$other"), 'still not another one';
  is [ $c->real_extra_roots ], [ "$extra", "$tmp/missing" ], 'undef is left out; a missing leaf stays (nothing can match below it)';
  is [ Langertha::Raider::PathConfine->new( root => "$root", extra_roots => ["$tmp/no/such/parent"] )->real_extra_roots ], [],
    'one without an existing parent is left out';
  is [ Langertha::Raider::PathConfine->new( root => "$root", extra_roots => [ "$extra", "$tmp/missing" ], dirs_only => 1 )->real_extra_roots ],
    ["$extra"], 'with dirs_only a missing one is left out';

  my @list = ("$extra");
  my $live = Langertha::Raider::PathConfine->new( root => "$root", extra_roots => sub { [@list] } );
  ok $live->allows("$extra"), 'a CodeRef answers on every call (ArrayRef form)';
  @list = ();
  ok !$live->allows("$extra"), 'and sees the list change';
  my $flat = Langertha::Raider::PathConfine->new( root => "$root", extra_roots => sub { ("$extra") } );
  ok $flat->allows("$extra"), 'a plain list works too';
};

subtest 'dirs_only keeps a file out of the roots' => sub {
  my $file = $extra->child('f.txt');
  my $any  = Langertha::Raider::PathConfine->new( root => "$root", extra_roots => ["$file"] );
  ok $any->allows("$file"), 'a file counts as a root by default';
  my $dirs = Langertha::Raider::PathConfine->new( root => "$root", extra_roots => ["$file"], dirs_only => 1 );
  ok !$dirs->allows("$file"), 'not with dirs_only';
};

subtest 'confine off, or no root: everything passes' => sub {
  ok( Langertha::Raider::PathConfine->new( root => "$root", confine => 0 )->allows("$other"), 'confine => 0' );
  ok( Langertha::Raider::PathConfine->new->allows("$other"), 'no root' );
  my $on = 1;
  my $c  = Langertha::Raider::PathConfine->new( root => "$root", confine => sub { $on } );
  ok !$c->allows("$other"), 'a CodeRef answering true';
  $on = 0;
  ok $c->allows("$other"), 'asked on every call: now false';
  is $c->confined, 0, 'confined says so';
};

done_testing;
