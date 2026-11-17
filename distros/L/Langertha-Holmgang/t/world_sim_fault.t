#!/usr/bin/env perl
# A simulator that fails in Perl (a die of its own code, or such a die it caught and
# returned as output) never hands the Perl text or a host file path to the model (k32).
# Claims: World->call answers with one generic, path-free tool error and ok 0; the
# original text goes into the gap of the simulation (report side only); an uncaught
# die leaves the state unchanged; output of the simulator around a caught die stays;
# simulated error texts of a simulator pass unchanged, also Perl-style lines that name
# a path of the simulated system, not a file of this process (ADR 0004). Invented
# worlds (ADR 0003).
use strict;
use warnings;
use utf8;
use Test::More;

use Langertha::Holmgang::Simulators;
use Langertha::Holmgang::World;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

{
  package Holmgang::Test::Brittle;
  use Moose;
  with 'Langertha::Holmgang::Role::AnswerWorld';
  sub device_type { 'brittle' }
  sub tools { return { crash => [], swallow => [], refuse => [], applog => [] } }
  sub tool {
    my ( $self, $w, $name, $args ) = @_;
    $w->{touched} = 1;
    if ( $name eq 'crash' ) { my $none; return ( scalar @$none, 1 ) }    # Perl dies here
    if ( $name eq 'swallow' ) {                                            # caught, returned as output
      my $e = do { local $@; eval { my $none; my @x = @$none; 1 }; $@ };
      $e =~ s/\s+\z//;
      return ( "step one done\n$e", 0 );
    }
    return ( "app log\nDied at /opt/app/lib/Foo.pm line 12.\nend", 1 ) if $name eq 'applog';    # simulated
    return ( "brittle: refused at gate line 3.", 0 );    # a simulated text, no Perl file
  }
  __PACKAGE__->meta->make_immutable;
}

my $sims = Langertha::Holmgang::Simulators->new->register('Holmgang::Test::Brittle');
my @tools = map { { name => $_, simulator => 'brittle', parameters => { type => 'object', properties => {} } } } qw( crash swallow refuse applog );
sub world { Langertha::Holmgang::World->new( state => { w => { type => 'brittle' } }, tools => \@tools, simulators => $sims ) }

my $PERL = qr{Can't use|\.p[lm]\b|\.t line|line \d+\.|/};

{
  my $w = world();
  my ( $out, $args, $ok, $gap ) = $w->call( crash => {} );
  unlike( $out, $PERL, 'uncaught die: no Perl text, no host path for the model' );
  like( $out, qr/\AFehler: /, '… a tool error like the other refusals of the World' );
  is( $ok, 0, '… the call failed' );
  like( $gap // '', qr/Can't use an undefined value as an ARRAY reference/, '… the original text is in the gap of the simulation' );
  ok( !$w->state->{w}{touched}, '… the state is unchanged' );
}

{
  my $w = world();
  my ( $out, $args, $ok, $gap ) = $w->call( swallow => {} );
  unlike( $out, $PERL, 'die caught and returned by the simulator: no Perl text, no host path' );
  like( $out, qr/\Astep one done\nFehler: /, '… its other output stays, the die line becomes the tool error' );
  is( $ok, 0, '… the call failed' );
  like( $gap // '', qr/Can't use an undefined value/, '… the original text is in the gap' );
}

{
  my ( $out, $args, $ok, $gap ) = world()->call( refuse => {} );
  is( $out, 'brittle: refused at gate line 3.', 'a simulated error text passes unchanged' );
  is( $gap, undef, '… and is no gap' );
}

{
  my ( $out, $args, $ok, $gap ) = world()->call( applog => {} );
  is( $out, "app log\nDied at /opt/app/lib/Foo.pm line 12.\nend", 'a simulated Perl-style log line of a simulated path passes unchanged' );
  is( $ok, 1, '… the call succeeds' );
  is( $gap, undef, '… and is no gap' );
}

{
  my ( $o1 ) = world()->call( crash => {} );
  my ( $o2 ) = world()->call( swallow => {} );
  ( my $line ) = $o2 =~ /^(Fehler: .*)\z/m;
  is( $line, $o1, 'one and the same tool error in both cases' );
}

# the real leak: a restic command the Linux simulator did not survive (Sim::Linux::Backup)
{
  my $f = sub { { content => $_[0], owner => 'root', group => 'root', mode => '0600', mtime => 'Oct 01 10:00' } };
  my $mk = sub { Langertha::Holmgang::World->new(
    state => { h => { type => 'linux', hostname => 'h', files => { '/root/pw' => $f->("pw\n") },
      restic_repos => { '/repo' => { password_file => '/root/pw', size => '1G',
        snapshots => [ { id => 'c0ffee01', time => '2026-01-01 00:00:00', host => 'h', paths => ['/x'], tags => [], files => {} } ] } } } },
    tools => [ { name => 'run_command', simulator => 'run_command',
      parameters => { type => 'object', required => [qw( host command )], properties => { host => { type => 'string' }, command => { type => 'string' } } } } ],
  ) };
  my ( $out ) = $mk->()->call( run_command => { host => 'h', command => 'restic -r /repo -p /root/pw forget latest' } );
  unlike( $out, $PERL, 'restic forget latest on linux: no Perl text, no host path for the model' );

  # a die inside a loaded simulator module that the Linux shell catches and returns:
  # a Perl error inside Backup.pm, forced for this call (_sel itself no longer dies
  # without a filter, k58)
  require Langertha::Holmgang::Sim::Linux::Backup;
  no warnings 'redefine';
  local *Langertha::Holmgang::Sim::Linux::Backup::_find_snap = sub { Langertha::Holmgang::Sim::Linux::Backup::_policy( 'x', {} ) };
  my ( $o2, undef, $ok, $gap ) = $mk->()->call( run_command => { host => 'h', command => 'echo before; restic -r /repo -p /root/pw forget latest' } );
  like( $o2, qr/\Abefore\nFehler: [^\n]*\z/, 'a caught die in a simulator module: its line becomes the tool error' );
  unlike( $o2, $PERL, '… no Perl text, no host path' );
  is( $ok, 0, '… the call failed' );
  like( $gap // '', qr/simulator error: Can't use .*Backup\.pm line \d+/, '… the original is in the gap' );
}

# the same line in a log file of a linux device, read through the shell
{
  my $log = "Oct 01 10:00:00 app1 app[42]: Died at /opt/app/lib/Foo.pm line 12.\nOct 01 10:00:01 app1 app[42]: Can't locate Bar.pm in \@INC at /opt/app/bin/app.pl line 3.\n";
  my $w = Langertha::Holmgang::World->new(
    state => { app1 => { type => 'linux', hostname => 'app1',
      files => { '/var/log/app.log' => { content => $log, owner => 'root', group => 'root', mode => '0644', mtime => 'Oct 01 10:00' } } } },
    tools => [ { name => 'run_command', simulator => 'run_command',
      parameters => { type => 'object', required => [qw( host command )], properties => { host => { type => 'string' }, command => { type => 'string' } } } } ],
  );
  my ( $out, $args, $ok, $gap ) = $w->call( run_command => { host => 'app1', command => 'cat /var/log/app.log' } );
  is( $out, $log =~ s/\n\z//r, 'cat of a simulated log with Perl-style lines: unchanged' );
  is( $ok, 1, '… the call succeeds' );
  is( $gap, undef, '… and is no gap' );
}

done_testing;
