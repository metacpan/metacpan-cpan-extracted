#!/usr/bin/env perl
# ABSTRACT: a hall running from the standalone (PAR::Packer) binary starts its raiders with that binary directly, never as "perl <binary>"

use strict;
use warnings;
use Test2::V0;
use JSON::PP ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::Hall qw( fake_hall run_spawns );

clear_engine_env();

# Inside a pp binary PAR.pm is loaded and PAR_PROGNAME names the
# executable; $^X there is a bare "perl" off PATH. This simulates that
# state for the duration of $code.
sub packed_as {
  my ( $exe, $code ) = @_;
  local $INC{'PAR.pm'} = '/loader/PAR.pm';
  local $ENV{PAR_PROGNAME} = "$exe";
  return $code->();
}

# A stand-in for the packed binary that is not Perl: run through perl it
# dies, exec'd directly it records its argv and ends the run.
sub sh_raider {
  my ( $dir ) = @_;
  my $exe = $dir->child('raider-x86_64-linux');
  $exe->spew_utf8(<<'SH');
#!/bin/sh
printf '%s\n' "$@" > "$FAKE_ARGV_LOG"
echo '{"version":1,"type":"run.finished","seq":1,"time":0,"status":"completed","response":"packed ok"}'
SH
  $exe->chmod(0755);
  return $exe;
}

subtest 'not packed: the raider script runs with this perl' => sub {
  my ( $hall ) = fake_hall();
  is( [ $hall->_raider_command ], [ $^X, $ENV{RAIDER_HALL_RAIDER_BIN} ], '$^X, then the script' );
};

subtest 'PAR_PROGNAME in the environment alone is not a packed binary' => sub {
  my ( $hall ) = fake_hall();
  # A plain perl started from a packed raider inherits PAR_PROGNAME.
  local $ENV{PAR_PROGNAME} = '/opt/raider';
  delete local $INC{'PAR.pm'};
  is( [ $hall->_raider_command ], [ $^X, $ENV{RAIDER_HALL_RAIDER_BIN} ], 'still $^X, then the script' );
};

subtest 'packed: the binary itself, exec\'d directly' => sub {
  my ( $hall, $tmp ) = fake_hall();
  delete local $ENV{RAIDER_HALL_RAIDER_BIN};
  my $exe = sh_raider($tmp);
  packed_as( $exe, sub {
    is( [ $hall->_raider_command ], [ "$exe" ], 'no perl in front of the binary' );
  } );
};

subtest 'packed: RAIDER_HALL_RAIDER_BIN still wins, also exec\'d directly' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $exe = sh_raider($tmp);
  packed_as( $tmp->child('elsewhere'), sub {
    local $ENV{RAIDER_HALL_RAIDER_BIN} = "$exe";
    is( [ $hall->_raider_command ], [ "$exe" ], 'the override, without perl' );
  } );
};

subtest 'packed: a spawned raider runs and finishes' => sub {
  my ( $hall, $tmp ) = fake_hall( yml => "raiders:\n  bjorn: {}\n" );
  delete local $ENV{RAIDER_HALL_RAIDER_BIN};
  my $exe = sh_raider($tmp);
  # No usable perl, as inside the binary: a raider started as
  # "$^X <binary>" never runs.
  local $^X = $tmp->child('no-perl-here')->stringify;
  my @done = packed_as( $exe, sub {
    run_spawns( $hall, 1, { name => 'bjorn', mission => 'go' } );
  } );
  is( scalar @done, 1, 'one raider.done' );
  is( $done[0]{status}, 'completed', 'the run completed' );
  is( $done[0]{response}, 'packed ok', 'with the binary\'s answer' );
  my @argv = path( $ENV{FAKE_ARGV_LOG} )->lines_utf8( { chomp => 1 } );
  is( $argv[0], '--stream-json', 'the binary got the raider options, not its own path' );
  is( [ @argv[ -2, -1 ] ], [ '--', 'go' ], 'mission last' );
};

done_testing;
