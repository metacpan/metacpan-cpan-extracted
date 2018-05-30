use strict;
use warnings;
use lib "lib";
use Test::More;
use LWP::CurlLog file => "curl.log", response => 0;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new();
$ua->get("http://www.google.com/");

my $content = `cat curl.log`;

my $test = $content =~ m{^#.* LWP request\n}m &&
           $content =~ m{^curl http://www.google.com/ -k\n}m;
ok $test, "log lines are as expected";

done_testing();

END {
    unlink "curl.log";
}
