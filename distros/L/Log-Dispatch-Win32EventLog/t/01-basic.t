use strict;

use constant NUM_ROUNDS => 2;

use Test::More tests => 8 + (7*NUM_ROUNDS);

use Win32;

BEGIN {
  use_ok('Win32::EventLog');
  use_ok('Log::Dispatch');
  use_ok('Log::Dispatch::Win32EventLog');
}

$Win32::EventLog::GetMessageText = 1;
is($Win32::EventLog::GetMessageText, 1, "Set Win32::EventLog::GetMessageText");

my $hnd;

sub open_log {
  $hnd = Win32::EventLog->new("Application", Win32::NodeName);
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
  return 0+$cnt;
}

sub get_last_event {
  my $event = { };
  if ($hnd->Read(
    EVENTLOG_BACKWARDS_READ() | 
      EVENTLOG_SEQUENTIAL_READ(), 0, $event)) {
    return $event;
  } else {
    diag("WARNING: Unable to read event log");
    return;
  }
}

open_log();

my $dispatch = Log::Dispatch->new;
ok( defined $dispatch, "new Log::Dispatch" );
is( ref($dispatch), 'Log::Dispatch', '... of the right type' );

$dispatch->add( Log::Dispatch::Win32EventLog->new(
  source => 'Win32EventLog test',
  min_level => 0, max_level => 7, name => 'test'
));

my %Events = ( ); # track events that we logged
my $time   = sub {sprintf '%04d%02d%02d%02d%02d%02d',
    $_[5]+1900, $_[4]+1, reverse(@_[0..3])}->(localtime);

# We run multiple rounds because we want to avoid checking passing the
# tests based on previous run of this script.  That, combined with
# using the time to differentiate runs, should make sure that we test
# for each session.

foreach my $tag (1..NUM_ROUNDS) {

  my $cnt1 = -1;
  $hnd->GetNumber($cnt1);

  $dispatch->log(level => 'emerg', message => "emergency,$tag,$time");
  my $cnt2 = -1;
  $hnd->GetNumber($cnt2);
  isnt($cnt2, -1, "got an event number for emerg $tag");
  cmp_ok( $cnt2, '>=', $cnt1, "emerg $tag" );
  $Events{"emergency,$tag,$time"} = 1;

  $dispatch->log(level => 'warning', message => "warning,$tag,$time");
  $Events{"warning,$tag,$time"} = 1;

  $cnt1 = -1;
  $hnd->GetNumber($cnt1);
  cmp_ok( $cnt2, '<=', $cnt1, "warning $tag" );

  $dispatch->log(level =>'info', message => "info,$tag,$time");
  $Events{"info,$tag,$time"} = 1;

  $cnt2 = -1;
  $hnd->GetNumber($cnt2);
  cmp_ok( $cnt2, '>=', $cnt1, "info $tag" );
}

{
  ok( (keys %Events) == (3*NUM_ROUNDS) );

#  require YAML;

  while ((keys %Events) && (my $event = get_last_event())) {

#    print STDERR YAML->Dump($event);

      my $string = $event->{Strings};

    if ( ($string =~ /(\w+)\,(\d+),(\d+)/) &&
         ($event->{Source} eq 'Win32EventLog test') ) {
      if( $3 == $time) {
        my $key = "$1,$2,$3";
        ok(delete $Events{$key}, "drained event $key");
      }
    }

  }
  is( (keys %Events), 0, "all events drained" );
}
