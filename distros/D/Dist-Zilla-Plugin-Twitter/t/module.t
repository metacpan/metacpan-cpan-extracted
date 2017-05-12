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

my $dist = 'DZ-Test';
my $result = test_dzil("corpus/$dist", [ qw(release) ]);

is($result->exit_code, 0, "dzil release would have exited 0");

my $module = $dist;
$module =~ s/-/::/g;
my $url = "http://p3rl.org/$module";
my $tweet = "[Twitter] Released $dist-v1.2.2 $url http://github.com/dude/project #bar";

ok(
  (grep { $_ eq $tweet } @{ $result->log_messages }),
  "we logged the Twitter message",
) or diag explain { STDOUT => $result->output, STDERR => $result->error };

my $no_shortener_msg = '[Twitter] dist.ini specifies to not use a URL shortener; using full URL';
ok (
   (grep { $_ eq $no_shortener_msg } @{ $result->log_messages }),
   q/Log claims we didn't use a URL shortener/,
) or diag explain { STDOUT => $result->output, STDERR => $result->error };

done_testing;
