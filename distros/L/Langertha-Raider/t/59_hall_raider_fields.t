#!/usr/bin/env perl
# ABSTRACT: persona becomes a --pack, the lib target reaches the raider and its PERL5LIB, mcp/isolated are only noted

use strict;
use warnings;
use Test2::V0;
use JSON::PP ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::Hall qw( fake_hall run_spawns );
use Langertha::Raider::CLI::Main;

clear_engine_env();

# A stand-in for bin/raider that records its argv and PERL5LIB.
my $FAKE = <<'PERL';
use strict;
use warnings;
use JSON::PP;
open my $a, '>>', $ENV{FAKE_ARGV_LOG} or die $!;
print $a JSON::PP->new->canonical->encode({ argv => [ @ARGV ], perl5lib => $ENV{PERL5LIB} }), "\n";
close $a;
$| = 1;
print JSON::PP->new->canonical->encode({ version => 1, type => 'run.finished', seq => 1, time => time,
  status => 'completed', response => 'ok' }), "\n";
exit 0;
PERL

# Every run the fake recorded: { argv => [...], perl5lib => '...' }.
sub runs {
  my $log = path( $ENV{FAKE_ARGV_LOG} );
  return [] unless -e $log;
  return [ map { JSON::PP->new->decode($_) } $log->lines ];
}

# The values of each FLAG before the -- in $argv.
sub flag_values {
  my ( $argv, $flag ) = @_;
  my @v;
  for my $i ( 0 .. $#$argv ) {
    last if $argv->[$i] eq '--';
    push @v, $argv->[ $i + 1 ] if $argv->[$i] eq $flag;
  }
  return \@v;
}

sub spawn_one {
  my ( $yml, $name ) = @_;
  my ( $hall, $tmp ) = fake_hall( script => $FAKE, yml => $yml );
  run_spawns( $hall, 1, { name => $name // 'bjorn', mission => 'go' } );
  return ( runs()->[0], $hall, $tmp );
}

subtest 'persona is passed as one more --pack, after packs' => sub {
  my ( $run ) = spawn_one("raiders:\n  bjorn: { persona: caveman, packs: [git-guru, polite] }\n");
  is( flag_values( $run->{argv}, '--pack' ), [qw( git-guru polite caveman )], 'packs, then the persona' );
  my $main = Langertha::Raider::CLI::Main->new;
  my %args = $main->app_args( ( $main->parse_options( @{ $run->{argv} } ) )[0] );
  is( $args{pack_names}, [qw( git-guru polite caveman )], 'raider CLI: pack_names' );
};

subtest 'a persona that packs already names is not passed twice' => sub {
  my ( $run ) = spawn_one("raiders:\n  bjorn: { persona: polite, packs: [polite, git-guru] }\n");
  is( flag_values( $run->{argv}, '--pack' ), [qw( polite git-guru )], 'no duplicate --pack' );
};

subtest 'a persona alone is the only --pack' => sub {
  my ( $run ) = spawn_one("raiders:\n  bjorn: { persona: caveman }\n");
  is( flag_values( $run->{argv}, '--pack' ), [ 'caveman' ], 'persona as --pack' );
};

subtest 'no persona, no packs: no --pack' => sub {
  my ( $run ) = spawn_one("raiders:\n  bjorn: {}\n");
  is( flag_values( $run->{argv}, '--pack' ), [], 'none' );
};

subtest 'default lib target: .raider/lib of the hall root' => sub {
  my ( $run, $hall, $tmp ) = spawn_one("raiders:\n  bjorn: {}\n");
  my $target = $tmp->child( '.raider', 'lib' )->stringify;
  is( $hall->lib_target, $target, 'lib_target' );
  is( flag_values( $run->{argv}, '-o' ), [ 'preferred_lib_target='.$target ], 'passed to the raider' );
  my @inc = split /:/, $run->{perl5lib};
  ok( ( grep { $_ eq $target.'/lib/perl5' } @inc ), 'its lib/perl5 is on PERL5LIB, where cpanm --local-lib installs' )
    or diag $run->{perl5lib};
  ok( !( grep { m{/\.raider-hall/raiders/} } @inc ), 'no per-raider lib dir' );

  # The raider CLI reads that argv into the target its perl_cpanm uses.
  my $main = Langertha::Raider::CLI::Main->new;
  my %args = $main->app_args( ( $main->parse_options( @{ $run->{argv} } ) )[0] );
  is( $args{engine_options}{preferred_lib_target}, $target, 'raider CLI: preferred_lib_target' );
  is( $args{pack_names}, undef, 'no packs' );
};

subtest 'preferred_lib_target of the hall config, relative to the root' => sub {
  my ( $run, $hall, $tmp ) = spawn_one("preferred_lib_target: .raider-hall/lib\nraiders:\n  bjorn: {}\n");
  my $target = $tmp->child( '.raider-hall', 'lib' )->stringify;
  is( $hall->lib_target, $target, 'lib_target' );
  is( flag_values( $run->{argv}, '-o' ), [ 'preferred_lib_target='.$target ], 'passed to the raider' );
  ok( ( grep { $_ eq $target.'/lib/perl5' } split /:/, $run->{perl5lib} ), 'its lib/perl5 is on PERL5LIB' )
    or diag $run->{perl5lib};
};

subtest 'longhouse adds longhouse/lib as well' => sub {
  my ( $run, $hall, $tmp ) = spawn_one("longhouse: 1\nraiders:\n  bjorn: {}\n");
  my @inc = split /:/, $run->{perl5lib};
  ok( ( grep { $_ eq $tmp->child( 'longhouse', 'lib' )->stringify } @inc ), 'longhouse/lib' );
  ok( ( grep { $_ eq $hall->lib_target.'/lib/perl5' } @inc ), 'and the lib target' );
};

subtest 'mcp and isolated on a raider entry are ignored and noted once' => sub {
  my ( $hall, $tmp ) = fake_hall( script => $FAKE,
    yml => "raiders:\n  bjorn: { mcp: [foo], isolated: 1 }\n  ivar: { persona: caveman }\n" );
  run_spawns( $hall, 2, { name => 'bjorn', mission => 'one' }, { name => 'ivar', mission => 'one' } );
  run_spawns( $hall, 1, { name => '1bjorn', mission => 'two' } );
  my @runs = @{ runs() };
  is( scalar @runs, 3, 'every run started' );
  for my $run (@runs) {
    ok( !( grep { /mcp|isolated/ } @{ $run->{argv} } ), 'nothing of mcp or isolated in the argv' );
  }
  my $logs = $tmp->child( '.raider-hall', 'logs' );
  my @notes = map { grep { /ignored/ } $logs->child($_)->lines_utf8 } qw( bjorn.log 1bjorn.log ivar.log );
  is( \@notes, [ "[hall] raider bjorn: isolated, mcp in .raider-hall.yml ignored\n" ],
    'one note, in the first slot log of the raider that carries them' );
};

done_testing;
