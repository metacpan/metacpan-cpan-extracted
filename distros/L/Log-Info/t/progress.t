# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info

This package tests the SINK_TERM_PROGRESS sink of Log::Info

=cut

use FindBin 1.42 qw( $Bin );
use Test 1.13 qw( ok plan );

use lib $Bin;
use test qw( DATA_DIR
             evcheck restore_output save_output );

BEGIN {
  # 1 for compilation test,
  eval "use Term::ProgressBar 2.00 qw( );";
  if ( $@ ) {
    print "1..0 # Skip: Term::ProgressBar not found\n";
    print STDERR $@
      if $ENV{TEST_DEBUG};
    exit 0;
  }

  plan tests  => 11,
       todo   => [],
}

# ----------------------------------------------------------------------------

use Log::Info qw( :DEFAULT :default_channels :log_levels );
$Log::Info::__SINK_TERM_FORCE = 50;

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

=head Tests 2--11: m/20 Done to TTY

=cut

{
  save_output('stderr', *STDERR{IO});
  ok(evcheck (sub {
                Log::Info::add_chan_trans(CHAN_PROGRESS,
                                          Log::Info::TRANS_CDT);
                Log::Info::set_channel_out_level(CHAN_PROGRESS,
                                                 LOG_INFO);
                Log::Info::add_sink(CHAN_PROGRESS,
                                    "foo",
                                    Log::Info::SINK_TERM_PROGRESS);
              }, 'm/20 Done to TTY (1)'),
    1, 'm/20 Done to TTY (1)');
  ok(evcheck (sub {
                Log(CHAN_PROGRESS, LOG_ERR, "[$_/20 Things Done]")
                  for 1..10;
              }, 'm/20 Done to TTY (2)'),
     1,
     'm/20 Done to TTY (2)');
  ok(evcheck (sub {
                Log(CHAN_PROGRESS, LOG_ERR, "Bingo!");
              }, 'm/20 Done to TTY (3)'),
     1,
     'm/20 Done to TTY (3)');
  ok(evcheck (sub {
                Log(CHAN_PROGRESS, LOG_ERR, "[$_/20 Things Done]")
                  for 11..14;
              }, 'm/20 Done to TTY (4)'),
     1,
     'm/20 Done to TTY (4)');
  ok(evcheck (sub {
                Log(CHAN_PROGRESS, LOG_ERR,
                    "[15/20 Things Done] Almost there...")
              }, 'm/20 Done to TTY (5)'),
     1,
     'm/20 Done to TTY (5)');
  ok(evcheck (sub {
                Log(CHAN_PROGRESS, LOG_ERR, "[$_/20 Things Done]")
                  for 16..20;
              }, 'm/20 Done to TTY (6)'),
     1,
     'm/20 Done to TTY (6)');
  my $err = restore_output('stderr');

  $err =~ s!^.*\r!!gm;
  print STDERR "ERR:\n$err\nlength: ", length($err), "\n"
    if $ENV{TEST_DEBUG};

  my @lines = split /\n/, $err;

  ok $lines[0],  qr/Bingo!/,            'm/20 Done to TTY (7)';
  ok $lines[1],  qr/Almost there.../,   'm/20 Done to TTY (8)';
  ok $lines[-1], qr/\[=+\]/,            'm/20 Done to TTY (9)';
  ok $lines[-1], qr/^\s*100%/,          'm/20 Done to TTY (10)';
}

__END__
