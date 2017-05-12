use strict;
use warnings;
use Time::HiRes;
use Capture::Tiny;
use Test::Most 'bail';

my $time                   = Time::HiRes::time;
$ENV{'BUBBLEBREAKER_TEST'} = 1;

ok( -e 'bin/bubble-breaker.pl',             'bin/bubble-breaker.pl exists' );
is( system("$^X -e 1"),                  0, "we can execute perl as $^X" );
my ($stdout, $stderr) = Capture::Tiny::capture { system("$^X bin/bubble-breaker.pl") };
ok( !$stderr, 'bubble-breaker ran ' . (Time::HiRes::time - $time) . ' seconds' );

$stdout ||= '';

if($stderr) {
    diag( "\$^X   = $^X");
    diag( "STDERR = $stderr");
}

pass 'Are we still alive? Checking for segfaults';

done_testing();
