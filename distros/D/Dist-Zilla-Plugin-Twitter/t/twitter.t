use strict;
use warnings;

use lib 't/lib';
use LWP::TestUA; # mocked UA
use Net::Netrc; # mocked version

use Test::More 0.88;
use File::Spec;

use Dist::Zilla::App::Tester;
use Test::DZil;

## SIMPLE TEST WITH DZIL::APP TESTER
$ENV{DZIL_GLOBAL_CONFIG_ROOT} = File::Spec->rel2abs( File::Spec->catdir(qw(corpus fake-HOME dzil)) );
$ENV{DZ_TWITTER_USERAGENT} = 'LWP::TestUA';

my $result = test_dzil('corpus/DZ1', [ qw(release) ]);

is($result->exit_code, 0, "dzil release would have exited 0");

my $dvname = 'DZ1-0.001';
my $url = "https://metacpan.org/release/AUTHORID/${dvname}/";
my $msg = "[Twitter] Released $dvname $url #foo";

ok(
  (grep { $_ eq $msg } @{ $result->log_messages }),
  "we logged the Twitter message",
) or diag "STDOUT:\n" . $result->output . "STDERR:\n" . $result->error;

done_testing;

