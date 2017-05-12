#!perl
use strict;
use warnings;
use Coro;
use FurlX::Coro;

my @coros;
foreach my $url(@ARGV) {
    push @coros, async {
        print "fetching $url\n";
        my $ua  = FurlX::Coro->new();
        $ua->env_proxy();
        my $res = $ua->head($url);
        printf "%s: %s\n", $url, $res->status_line();
    }
}

$_->join for @coros;

