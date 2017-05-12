# Testing the "Transfer truncated: only ... out of .. bytes received"
# case.

use strict;
use Test::More;

use File::Temp qw(tempfile);
use Getopt::Long qw(GetOptions);
use LWPx::ParanoidAgent;

my $url;
GetOptions("url=s" => \$url)
    or die "usage: $0 [-url url]";

if (!$url) {
    plan skip_all => 'Mirror tests needs -url option';
    exit;
}

plan tests => 1;

my(undef, $tempfile) = tempfile(UNLINK => 1);
unlink $tempfile; # we only need the filename
my $ua = LWPx::ParanoidAgent->new;
my $resp = $ua->mirror($url, $tempfile);
ok($resp->is_success)
    or diag($resp->as_string);
