use Test::More tests => 4;

BEGIN { use_ok('Mac::SleepEvent') };

use Mac::SleepEvent;

my %callbacks = (
  sleep  => sub {'sleep'},
  wake   => sub {'wake'},
  logout => sub {'logout'},
);

my $sn = Mac::SleepEvent->new(%callbacks);

ok $sn->{sleep_callback}()  eq 'sleep';
ok $sn->{wake_callback}()  eq 'wake';
ok $sn->{logout_callback}() eq 'logout';
