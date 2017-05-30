use strict;
use warnings;
use lib "lib";
use Test::More;
use LWP::CurlLog;
use LWP::UserAgent;

$LWP::CurlLog::log_file = "curl.log";
$LWP::CurlLog::log_output = 0;
my $ua = LWP::UserAgent->new();
$ua->get("http://www.google.com/");

open my $fh, "<", "curl.log" or die "Can't open curl.log: $!";
my $content = do {local $/; <$fh>};
close $fh;

my $test = $content =~ m{^#.* LWP request\n}m &&
           $content =~ m{^curl http://www.google.com/ -k\n}m;
ok $test, "log lines are as expected";

done_testing();

END {
    unlink "curl.log";
}
