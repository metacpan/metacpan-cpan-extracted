use strict;

use constant NUM_ROUNDS => 2;

use Test::More tests => 5 + (6*NUM_ROUNDS);

BEGIN {
  use_ok('Win32::EventLog');
}

TODO: {
    local $TODO = "Win32::EventLog::GetMessageText misbehaviour";
    is($Win32::EventLog::GetMessageText, 1, "Set Win32::EventLog::GetMessageText");
}

my $hnd;

sub open_log {
  $hnd = new Win32::EventLog("Win32EventLog Log4perl Test", Win32::NodeName);
}

END {
  if ($hnd) {
    $hnd->Close;
    $hnd = undef;
  }
}

sub get_number {
  my $cnt = -1;
  $hnd->GetNumber($cnt);
  return $cnt;
}

sub get_last_event {
  my $event = { };
  if ($hnd->Read(
    EVENTLOG_BACKWARDS_READ() | 
      EVENTLOG_SEQUENTIAL_READ(), 0, $event)) {
    return $event;
  } else {
    print "\x23 WARNING: Unable to read event log";
    return;
  }
}

eval {
  require Log::Log4perl;
  import Log::Log4perl;
};

my $has_it = ($@) ? 0 : 1;

SKIP: {

  skip "Log::Log4perl not found", 3+(6*NUM_ROUNDS)
    unless ($has_it);

  open_log();

  my $config = qq{
log4perl.logger.test               = INFO, EventLog

log4perl.appender.EventLog         = Log::Dispatch::Win32EventLog
log4perl.appender.EventLog.layout  = Log::Log4perl::Layout::SimpleLayout
log4perl.appender.EventLog.source  = Win32EventLog Log4perl Test
log4perl.appender.EventLog.Threshold = INFO
};

  Log::Log4perl::init( \$config );
  my $log = Log::Log4perl->get_logger('test');

  ok( defined $log, "get_logger" );

  my %Events = ( );                # track events that we logged
  my $time   = sub {sprintf '%04d%02d%02d%02d%02d%02d',
    $_[5]+1900, $_[4]+1, reverse(@_[0..3])}->(localtime);

  # We run multiple rounds because we want to avoid checking passing the
  # tests based on previous run of this script.  That, combined with
  # using the time to differentiate runs, should make sure that we test
  # for each session.

  foreach my $tag (1..NUM_ROUNDS) {

    my $cnt1 = get_number();

    $log->error("error,$tag,$time");
    $Events{"error,$tag,$time"} = 1;

    my $cnt2 = get_number();
    cmp_ok( $cnt2, '>=', $cnt1, "round $tag get 1" );

    $log->warn("warning,$tag,$time");
    $Events{"warning,$tag,$time"} = 1;

    $cnt1 = get_number();
    cmp_ok( $cnt1, '>=', $cnt2, "round $tag get 1" );

    $log->info("info,$tag,$time");
    $Events{"info,$tag,$time"} = 1;

    $cnt2 = get_number();
    cmp_ok( $cnt2, '>=', $cnt1, "round $tag get 1" );
  }

  {
    is( (keys %Events), (3*NUM_ROUNDS), "logged all events" );

    while ((keys %Events) && (my $event = get_last_event())) {

      my $string = $event->{Strings};

      if ( ($string =~ /(\w+)\,(\d+),(\d+)/) &&
           ($event->{Source} eq 'Win32EventLog Log4perl Test') ) {
        if ( $3 == $time) {
          my $key = "$1,$2,$3";
          ok(delete $Events{$key}, "removed $key");
        }

      }
    }
    is( (keys %Events), 0, "all events accounted for" );
  }
};
