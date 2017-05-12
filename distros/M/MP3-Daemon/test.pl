use Test;
use MP3::Daemon;
use MP3::Daemon::Simple;
use MP3::Daemon::PIMP;
use strict;

BEGIN { plan tests => 2 }

ok(1);

my $rc;
$rc = system("perl -Iblib/lib -c bin/mp3 2> /dev/null");
ok(!$rc);

# $rc = system("perl -Iblib/lib -c bin/pimp 2> /dev/null");
# ok(!$rc);
