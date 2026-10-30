#!/usr/bin/env perl
# ABSTRACT: Paths outside the root in the Claude layout: the policy asks, rules allow, symlinks count (ADR 0023)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Langertha::Raider::Permissions;
use Langertha::Raider::FileTools qw( build_file_tools_server );

my $class = 'Langertha::Raider::Permissions';
my $tmp   = Path::Tiny->tempdir->realpath;
my $root  = $tmp->child('proj');
my $home  = $tmp->child('home');
my $out   = $tmp->child('elsewhere');
my $docs  = $tmp->child('docs');
$_->mkpath for $root, $home, $out, $docs;
$out->child('f.txt')->spew("outside\n");
my $has_symlink = symlink "$out", $root->child('link')->stringify;

sub policy {
  my ( %arg ) = @_;
  return $class->new( root => "$root", home => "$home", ask_outside_roots => 1, %arg );
}
sub tc { { name => $_[0], source => 'engine:1', arguments => $_[1] // {} } }
sub decision { $_[0]->decide( $_[1] ) }

subtest 'outside_paths' => sub {
  my $p = policy( additional_directories => [ { path => "$docs", source => 'test' } ] );
  is [ $p->outside_paths( tc( read_file => { path => 'lib/x.pm' } ) ) ], [], 'inside the root';
  is [ $p->outside_paths( tc( read_file => { path => "$docs/a" } ) ) ], [], 'inside an additional directory';
  is [ $p->outside_paths( tc( read_file => { path => "$out/f.txt" } ) ) ], [ "$out/f.txt" ], 'outside';
  is [ $p->outside_paths( tc( read_file => { path => '../elsewhere/f.txt' } ) ) ], [ "$out/f.txt" ], '../ taken out first';
  is [ $p->outside_paths( tc( grep => { pattern => 'x' } ) ) ], [], 'grep without a path searches the root';
  is [ $p->outside_paths( tc( bash => { command => "cat $out/f.txt" } ) ) ], [], 'bash has no path argument';
  SKIP: {
    skip 'no symlinks', 1 unless $has_symlink;
    is [ $p->outside_paths( tc( read_file => { path => 'link/f.txt' } ) ) ], [ "$out/f.txt" ],
      'a symlink out of the root: the real path is outside';
  }
};

subtest 'the modes ask, rules allow, deny and plan win' => sub {
  my $read  = tc( read_file  => { path => "$out/f.txt" } );
  my $write = tc( write_file => { path => "$out/new.txt" } );
  my $multi = tc( multi_edit => { path => "$out/f.txt" } );
  for my $mode (qw( default acceptEdits auto plan )) {
    my $d = decision( policy( mode => $mode ), $read );
    is $d->{verdict}, 'ask', "$mode asks before reading outside";
    like $d->{reason}, qr/read_file requested permissions to read from \Q$out\E\/f\.txt, which is outside the project root and the additional directories, but you haven't granted it yet/, '... saying so';
  }
  is decision( policy( mode => 'acceptEdits' ), $write )->{verdict}, 'ask', 'acceptEdits does not take a write outside';
  like decision( policy( mode => 'acceptEdits' ), $multi )->{reason}, qr/multi_edit requested permissions to write to/, 'multi_edit too';
  is decision( policy( mode => 'plan' ), $write )->{verdict}, 'deny', 'plan refuses the write first';
  is decision( policy( mode => 'bypassPermissions' ), $read )->{verdict}, 'allow', 'bypassPermissions reaches it';
  is decision( policy( mode => 'bypassPermissions', rules => { deny => [ { rule => "Read(/$out/**)", source => 't' } ] } ), $read )->{verdict},
    'deny', 'a deny rule holds in bypassPermissions';
  my $allowing = policy( rules => { allow => [ { rule => "Read(/$out/**)", source => 't' } ] } );
  is decision( $allowing, $read )->{verdict}, 'allow', 'Read(//abs/**) allows the read';
  is decision( $allowing, tc( grep => { pattern => 'x', path => "$out" } ) )->{verdict}, 'allow', 'and the search';
  is decision( $allowing, $write )->{verdict}, 'ask', 'not the write';
  is decision( policy( rules => { allow => [ { rule => "Edit(/$out/**)", source => 't' } ] } ), $multi )->{verdict}, 'allow',
    'Edit(//abs/**) covers multi_edit';
  is decision( policy( ask_outside_roots => 0 ), $read )->{verdict}, 'allow',
    'without ask_outside_roots (the raider layout) the policy leaves it to the confined tool';
  is decision( policy(), tc( read_file => { path => 'inside.txt' } ) )->{verdict}, 'allow', 'inside the root nothing changes';
};

subtest 'suggested rules and how the search hides' => sub {
  my $p = policy();
  is $p->suggest_rule( tc( read_file => { path => "$out/f.txt" } ) ), "Read(/$out/**)", 'read_file: the directory of the file';
  is $p->suggest_rule( tc( grep => { pattern => 'x', path => "$out" } ) ), "Read(/$out/**)", 'grep: the directory searched';
  is $p->suggest_rule( tc( multi_edit => { path => "$out/f.txt" } ) ), "Edit(/$out/**)", 'multi_edit: an Edit rule';
  is $p->suggest_rule( tc( multi_edit => { path => 'src/a.txt' } ) ), 'Edit(src/**)', 'multi_edit inside the root';
  my $hiding = policy( rules => { deny => [ { rule => 'Read(./secrets/**)', source => 't' } ] } );
  ok !$hiding->hides_read("$out/f.txt"), 'a file outside found by a search the gate let through is not hidden';
  ok $hiding->hides_read("$root/secrets/k"), 'a denied one is';
};

subtest 'sub-runs and revisions keep it' => sub {
  my $p = policy();
  ok $p->for_subrun->ask_outside_roots, 'for_subrun';
  isnt $p->policy_revision, policy( ask_outside_roots => 0 )->policy_revision, 'part of the revision';
  ok $class->from_sources( root => "$root", home => "$home", ask_outside_roots => 1 )->ask_outside_roots, 'from_sources';
};

subtest 'unconfined file tools reach outside, the confined ones do not' => sub {
  my $run = sub {
    my ( $server, $name, $args ) = @_;
    my ($tool) = grep { $_->name eq $name } @{ $server->tools };
    my $r = $tool->code->( $tool, $args );
    return ( $r->{content}[0]{text}, $r->{isError} ? 1 : 0 );
  };
  my $confine = 1;
  my $files = build_file_tools_server( root => "$root", confine => sub { $confine } );
  my ( $text, $err ) = $run->( $files, read_file => { path => "$out/f.txt" } );
  is $err, 1, 'confined: refused';
  like $text, qr/Path escapes root/, '... by the tool';
  $confine = 0;
  ( $text, $err ) = $run->( $files, read_file => { path => "$out/f.txt" } );
  is [ $text, $err ], [ "1\toutside\n2\t", 0 ], 'unconfined (asked on every call): read';
};

done_testing;
