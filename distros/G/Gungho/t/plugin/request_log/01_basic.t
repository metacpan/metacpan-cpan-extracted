use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;

BEGIN
{
    if (! $ENV{GUNGHO_TEST_LIVE}) {
        plan skip_all => "Enable GUNGHO_TEST_LIVE to run these tests";
    } elsif (! GunghoTest::assert_engine()) {
        plan(skip_all => "No engine available");
    } else {
        eval "use IO::Scalar";
        if ($@) {
            plan(skip_all => "IO::Scalar not installed: $@");
        } else {
            plan(tests => 5);
            use_ok("Gungho::Inline");
        }
    }
}

my $output = '';
my $fh     = IO::Scalar->new(\$output) ||
    die "Failed to open handle to scalar \$output";

# If we're not connect to the net the request itself may fail, but we're
# not interested in that
Gungho->run(
    {
        plugins => [
            { module => "RequestLog",
              config => [
                  { module => "Handle", name => 'request_log', handle => $fh, min_level => 'debug'}
              ]
            },
        ],
        provider => sub {
            my($p, $c) = @_;

            foreach my $url qw( http://www.perl.com http://search.cpan.org ) {
                $c->send_request(Gungho::Request->new(GET => $url));
            }
        }
    }
);

like($output, qr{^# \d+(?:\.\d+)? | http://www\.perl\.com | (?:[a-f0-9]+)}, "fetch start for www.perl.com");
like($output, qr{^# \d+(?:\.\d+)? | http://search\.cpan\.org | (?:[a-f0-9]+)}, "fetch start for search.cpan.org");
like($output, qr{^\d+(?:\.\d+)? | \d+(?:\.\d+)? | \d{3} | http://www\.perl\.com | (?:[a-f0-9]+)}, "http://www.perl.com is properly logged");
like($output, qr{^\d+(?:\.\d+)? | \d+(?:\.\d+)? | \d{3} | http://search\.cpan\.org | (?:[a-f0-9]+)}, "http://search.cpan.org is properly logged");