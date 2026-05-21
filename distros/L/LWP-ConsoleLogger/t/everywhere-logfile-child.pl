use strict;
use warnings;

use LWP::ConsoleLogger::Everywhere (); # reads $ENV{LWPCL_LOGFILE} at use time
use LWP::UserAgent                 ();
use Path::Tiny                     qw( path );

my $url = 'file:///' . path('t/test-data/unicode.html')->absolute;
my $ua  = LWP::UserAgent->new;
$ua->get($url);
exit 0;
