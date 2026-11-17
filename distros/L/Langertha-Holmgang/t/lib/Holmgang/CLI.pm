package Holmgang::CLI;
# Test helpers for the CLI tests: the commands in process with captured output,
# and invented suites (ADR 0003 -- no real case, no real target).
use strict;
use warnings;
use Exporter qw( import );
use Encode ();

use Holmgang::SuiteDir qw( suite_dir $FAN_HEAD $FAN_CASE );
use Langertha::Holmgang::CLI;

our @EXPORT_OK = qw( cli good_suite bad_suite threshold_suite $BAD_CASE );

# the fan case whose wrong solution passes: lint refuses it
our $BAD_CASE = <<'Y';
id: c1
title: Cool the room somehow
messages: [ { role: user, content: "It is hot in here." } ]
state: { fan: { level: off } }
rules:
  - { title: fan running, state: fan.level, in: [low, high] }
solution: [ { tool: fan_set, args: { level: high } } ]
alternatives: [ { title: stepwise, calls: [ { tool: fan_set, args: { level: low } }, { tool: fan_set, args: { level: high } } ] } ]
wrong_solutions: [ { title: low only, calls: [ { tool: fan_set, args: { level: low } } ] } ]
Y

my $CLI = Langertha::Holmgang::CLI->new;   # one loader for every call

# cli(@argv) -> ( $exit_code, $stdout, $stderr ), output as characters
sub cli {
  my ( @argv ) = @_;
  my ( $out, $err ) = ( '', '' );
  open my $o, '>:encoding(UTF-8)', \$out or die;
  open my $e, '>:encoding(UTF-8)', \$err or die;
  my $code = Langertha::Holmgang::CLI->new( out => $o, err => $e, loader => $CLI->loader )->run(@argv);
  close $o;
  close $e;
  return ( $code, Encode::decode( 'UTF-8', $out ), Encode::decode( 'UTF-8', $err ) );
}

sub good_suite { suite_dir(@_) }

sub bad_suite { suite_dir( @_, cases => { 'c0.yaml' => $FAN_CASE =~ s/c1/c0/r, 'c2.yaml' => $BAD_CASE =~ s/c1/c2/r } ) }

sub threshold_suite { suite_dir( @_, head => $FAN_HEAD."threshold: { pass_rate: 0.9 }\n" ) }

1;
