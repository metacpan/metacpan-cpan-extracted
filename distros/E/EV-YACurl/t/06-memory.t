use strict;
use warnings;
use lib 't/lib';
use Test::More;
use POSIX ();
use TestServer;
use EV::YACurl ':constants';

TestServer::watchdog(120);

BEGIN {
    eval { require Test::LeakTrace; 1 }
        or plan skip_all => 'Test::LeakTrace is required for this test';
}
use Test::LeakTrace qw(leaked_count);

my $server = TestServer->new(sub { (200, [], 'OK') });
my $base = $server->base_url;

plan tests => 6;

# Perl caches method lookups and curl warms up global state on first use, so
# measure only once everything on the path has been exercised.
{
    my $done = 0;
    EV::YACurl->new({})->request(sub { $done = 1 },
        { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
    EV::run until $done;
}

{
    my $leaks = leaked_count {
        my $client = EV::YACurl->new({});
        my $done = 0;
        $client->request(sub { $done = 1 }, {
            CURLOPT_URL => "$base/",
            CURLOPT_WRITEFUNCTION => sub { },
        });
        EV::run until $done;
    };

    ok($leaks <= 2, "Single request: minimal leaks ($leaks)");
}

{
    my $leaks1 = leaked_count {
        my $client = EV::YACurl->new({});
        for (1..5) {
            my $done = 0;
            $client->request(sub { $done = 1 }, {
                CURLOPT_URL => "$base/",
                CURLOPT_WRITEFUNCTION => sub { },
            });
            EV::run until $done;
        }
    };

    my $leaks2 = leaked_count {
        my $client = EV::YACurl->new({});
        for (1..20) {
            my $done = 0;
            $client->request(sub { $done = 1 }, {
                CURLOPT_URL => "$base/",
                CURLOPT_WRITEFUNCTION => sub { },
            });
            EV::run until $done;
        }
    };

    ok($leaks2 <= $leaks1 + 5,
       "Sequential requests: four times the work, no more leaks ($leaks1 vs $leaks2)");
}

{
    my $leaks = leaked_count {
        my $client = EV::YACurl->new({});
        my $completed = 0;
        my $n = 20;

        for (1..$n) {
            $client->request(sub { $completed++ }, {
                CURLOPT_URL => "$base/",
                CURLOPT_WRITEFUNCTION => sub { },
            });
        }
        EV::run until $completed >= $n;
    };

    ok($leaks <= 5, "Concurrent requests: minimal leaks ($leaks)");
}

{
    my $leaks = leaked_count {
        my $client = EV::YACurl->new({
            CURLMOPT_MAX_TOTAL_CONNECTIONS => 10,
        });

        for (1..5) {
            my $done = 0;
            my $body = '';
            $client->request(sub { $done = 1 }, {
                CURLOPT_URL => "$base/",
                CURLOPT_HTTPHEADER => ["X-Test: value", "X-Another: header"],
                CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
                CURLOPT_HEADERFUNCTION => sub { },
            });
            EV::run until $done;
        }
    };

    ok($leaks <= 5, "Complex requests: minimal leaks ($leaks)");
}

{
    my $leaks = leaked_count {
        my $client = EV::YACurl->new({});
        my $response;
        my $done = 0;

        $client->request(sub {
            ($response, my $err) = @_;
            if ($response) {
                my $code = $response->getinfo(CURLINFO_RESPONSE_CODE);
                my $time = $response->getinfo(CURLINFO_TOTAL_TIME_T);
            }
            $done = 1;
        }, {
            CURLOPT_URL => "$base/",
            CURLOPT_WRITEFUNCTION => sub { },
        });

        EV::run until $done;
        undef $response;
    };

    ok($leaks <= 5, "Response lifecycle: minimal leaks ($leaks)");
}

SKIP: {
    my $statm = "/proc/$$/statm";
    skip 'address space check needs Linux /proc', 1 unless -r $statm;
    skip 'address space says nothing under valgrind', 1
        if ($ENV{LD_PRELOAD} || '') =~ /vgpreload/;

    my $get_mem = sub {
        open my $fh, '<', $statm or return 0;
        my $line = <$fh>;
        my ($size) = split /\s+/, $line;
        my $page = POSIX::sysconf(POSIX::_SC_PAGESIZE());
        $page = 4096 if !defined $page || $page < 1;
        return $size * $page;
    };

    {
        my $client = EV::YACurl->new({});
        for (1..50) {
            my $done = 0;
            $client->request(sub { $done = 1 }, {
                CURLOPT_URL => "$base/",
                CURLOPT_WRITEFUNCTION => sub { },
            });
            EV::run until $done;
        }
    }

    my $mem_before = $get_mem->();

    {
        my $client = EV::YACurl->new({});
        for (1..200) {
            my $done = 0;
            $client->request(sub { $done = 1 }, {
                CURLOPT_URL => "$base/",
                CURLOPT_HTTPHEADER => ["X-Iter: $_"],
                CURLOPT_WRITEFUNCTION => sub { },
            });
            EV::run until $done;
        }
    }

    my $mem_after = $get_mem->();
    my $growth = $mem_after - $mem_before;
    my $growth_mb = $growth / 1024 / 1024;

    ok($growth < 2 * 1024 * 1024, sprintf("Address space stable: %.2f MB growth", $growth_mb))
        or diag("Memory grew from $mem_before to $mem_after ($growth_mb MB)");
}
