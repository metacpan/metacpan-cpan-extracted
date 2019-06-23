# NAME

Endoscope - inspect live Perl systems

# SYNOPSIS

    use Endoscope;
    my $scope = Endoscope->new();
    $scope->add(__FILE__, __LINE__ + 3, '$foo');
    $scope->apply();
    my $foo = "super cool data";
    my $bar = "baz"; # print: Endoscope: test.pl/6/$foo = 'super cool data (len 15)'

# DESCRIPTION

[Endoscope](https://metacpan.org/pod/Endoscope) is an [endoscope](https://en.wikipedia.org/wiki/Endoscope)
for live Perl programs.

It provides dynamic run-time introspection of Perl variables at arbitrary
locations in the program. Think of it like inserting `say Dumper($foo)` at
_just_ the right location in your code to figure out why it is misbehaving --
without restarting `perl` or worrying whether `$foo` contains gigabytes of
state.

It accomplishes this with low performance impact. See ["PERFORMANCE"](#performance) for more
information on overhead. It is a major goal for this module and its
subcomponents to be suitable for always-on production usage.

This is a very powerful capability with significant implications for the
security of the data in a program's memory. As such, any usage of
`Endoscope` should carefully guard access to the control or reporting
interfaces. See ["SECURITY"](#security) for a more comprehensive discussion.

# METHODS

## new

    my $e = Endoscope->new(%options);

Create a new Endoscope object. `%options` may be empty, or contain any of the
following keys:

- `monitor`

    Subroutine to invoke with the result of the query. Use this to push to
    a logging pipeline or other human-facing debugging tool.

    Default implementation:

        sub {
            my ($file, $line, $query, $result) = @_;
            say STDERR "Endoscope: $file/$line/$query = $result";
        }

## add

    my $e = Endoscope->new();
    $e->add("foo.pl", 42, '$foo->[0]');

Add a [Devel::Optic](https://metacpan.org/pod/Devel::Optic) query to the scope. Takes filename, line number, and
query as arguments.  An optional fourth argument, if true, will cause the query
to fire every time the codepath is executed, rather than just once. Use that
option with care.

## remove

    $e->remove("foo.pl", 42);

Remove any query assigned to the file/line pair.

## apply

    $e->apply();

`apply` synchronizes the set of 'added' or 'removed' queries with the
underlying system, [Devel::Probe](https://metacpan.org/pod/Devel::Probe). Call this after 'adding' or 'removing'
queries, or to reset 'once' queries after they've fired. If Endoscope is
integrated with a web application, this would be called once per request early
in the request handling lifecycle.

## clear

`clear` removes all queries from settings. Call `apply` to remove them for
real.

# PERFORMANCE

`Endoscope` and supporting libraries `Devel::Probe` and `Devel::Optic`
attempt to be suitable for usage in performance sensitive production
environments. However, 'performance sensitive' covers a wide range of
situations. As a rule of thumb, if the code you're querying strives to minimize
subroutine calls for performance reasons, it would be best to stick to the
default 'once' setting for queries, and be mindful of the amount of work
performed in the 'monitor'.

## BENCHMARK

Benchmarking is very difficult, and for the sake of this document I'm going to
quote results from my laptop. The goal of this benchmark report is to give you
a general sense of how `Endoscope` performs. Your milage may vary.

NOTE: all of the `Endoscope` tests are conducted with at least one query
active and firing each time the associated code is executed. If no queries are
configured, `Endoscope` has no measurable overhead. The recommended setup is
for `Endoscope` to be installed and listening, and have the program expose
a privileged interface for system operators to set queries which execute once,
dump some information, and then remove themselves. This model of integration
should be suitable for all but the tightest performance requirements.

### TEST SETUP

The testbed is a "Hello World" Mojolicious application using Mojolicious in the
following configuration:

        $ mojo version
        CORE
          Perl        (v5.28.1, linux)
          Mojolicious (8.17, Supervillain)

        OPTIONAL
          Cpanel::JSON::XS 4.04+  (4.09)
          EV 4.0+                 (4.25)
          IO::Socket::Socks 0.64+ (n/a)
          IO::Socket::SSL 2.009+  (2.066)
          Net::DNS::Native 0.15+  (n/a)
          Role::Tiny 2.000001+    (2.000006)

        This version is up to date, have fun!

The test machine has 16gb of RAM and an Intel Core i7-8650U (4 cores, 8 threads) CPU.

### TEST PROGRAMS

Baseline program:

        use Mojolicious::Lite;

        get '/hello' => sub {
                my $c = shift;
                my $app = app;
                $c->render(text => "hello!\n");
        };

        app->start;

`Endoscope` variant program:

        use Mojolicious::Lite;
        use Endoscope;
        my $scope = Endoscope->new(monitor => sub {
                my ($file, $line, $query, $result) = @_;
                app->log->debug("$file/$line/$query = $result");
        });
        $scope->add(__FILE__, __LINE__ + 6, '$app', 1); # 1 means 'run it every time that line executes'
        $scope->apply();

        get '/hello' => sub {
                my $c = shift;
                my $app = app;
                $c->render(text => "hello!\n");
        };

        app->start;

These programs store 'app' into `$app` in order to give `Endoscope` a large structure to query.

The Mojo app is running in 'production' mode.

    $ perl test.pl daemon -m production

This avoids measuring the performance of printing logs to `STDERR`.

The load generator is [wrk2](https://github.com/giltene/wrk2), invoked in the following way:

    $ wrk 'http://localhost:3000/hello' -R 2500 -d 60

#### HOW TO READ THE RESULTS

The test cases use a target request rate of 2500 RPS. This exceeds the baseline
single-core performance of Mojolicious on my laptop. As such, the latency
numbers look really high: we are saturating the test programs.

I did this because lower request rates, like 2000 RPS, resulted in
both test programs easily managing the request rates with average latencies in
the single-digit millisecond range. This demonstrated no clear relationship
between the two programs: sometimes the program that did strictly more work was
_faster_, which is a sign of a broken benchmark.

Due to the saturation, the latency numbers are not very meaningful.

However, the request rate that the program manages to output in the face of
saturation is useful: the difference in RPS delivered by the baseline vs. the
Endoscope variant can be read as the "overhead" introduced by `Endoscope`.

### BASELINE

        $ wrk 'http://localhost:3000/hello' -R 2500 -d 60
        Running 1m test @ http://localhost:3000/hello
          2 threads and 10 connections
          Thread calibration: mean lat.: 271.343ms, rate sampling interval: 1068ms
          Thread calibration: mean lat.: 298.969ms, rate sampling interval: 1011ms
          Thread Stats   Avg      Stdev     Max   +/- Stdev
                Latency     1.89s   802.43ms   3.61s    60.09%
                Req/Sec     1.18k    15.16     1.22k    67.37%
          141956 requests in 1.00m, 20.20MB read
        Requests/sec:   2365.95
        Transfer/sec:    344.70KB

### `ENDOSCOPE` VARIANT

        $ wrk 'http://localhost:3000/hello' -R 2500 -d 60
        Running 1m test @ http://localhost:3000/hello
          2 threads and 10 connections
          Thread calibration: mean lat.: 686.950ms, rate sampling interval: 2496ms
          Thread calibration: mean lat.: 680.839ms, rate sampling interval: 2420ms
          Thread Stats   Avg      Stdev     Max   +/- Stdev
                Latency     4.59s     1.87s    8.80s    58.91%
                Req/Sec     1.09k    10.68     1.11k    70.00%
          130455 requests in 1.00m, 18.56MB read
        Requests/sec:   2174.22
        Transfer/sec:    316.77KB

### DISCUSSION

The baseline program delivered 2365 requests per second in the face of clients
demanding 2500 requests per second. The `Endoscope` variant delivered 2174
requests per second, or 91.92% of baseline. In other words, `Endoscope` in the
given configuration reduces capacity by about 8.1%.

8.1% can be seen as a lower bound on overhead with a query firing once per
request on saturated, CPU-bound Mojolicious web apps. Queries that fire more
than once per request, or which do expensive work while exporting data, may
have a higher impact. However, most real-world applications:

- Do not run at their 'red line' of capacity, and
- Do significantly more work than render out "Hello World".

So, you are encouraged to measure for yourself.

#### UNSATURATED

In order to avoid misrepresenting the performance of Mojolicious (or my laptop
:)), here's an example "unsaturated" test case, which is representative of the
performance of both the baseline and the variant. I won't specify which one
this is, because the variance from run to run is too high to get a meaningful
ordering:

        $ wrk 'http://localhost:3000/hello' -R 2000 -d 60
        Running 1m test @ http://localhost:3000/hello
          2 threads and 10 connections
          Thread calibration: mean lat.: 5.213ms, rate sampling interval: 10ms
          Thread calibration: mean lat.: 5.041ms, rate sampling interval: 10ms
          Thread Stats   Avg      Stdev     Max   +/- Stdev
                Latency     4.28ms    0.88ms  21.57ms   92.20%
                Req/Sec     1.05k   122.54     1.67k    65.38%
          119971 requests in 1.00m, 17.07MB read
        Requests/sec:   1999.48
        Transfer/sec:    291.31KB

# SECURITY

`Endoscope` is a powerful tool for debugging running systems by inspecting
their memory. This means that anyone who is able to configure `Endoscope`
queries and view their output can read the contents of nearly any variable
present in memory. As such, access to these capabilities should be carefully
guarded.

For example, if `Endoscope` is integrated into a web framework and exposes
a special HTTP endpoint for configuring queries, that endpoint should only be
accessible from the host where the application is running, not externally.
Additionally, that HTTP endpoint should be gated by strong
authentication/authorization.

# SEE ALSO

- [Devel::Optic](https://metacpan.org/pod/Devel::Optic)
- [Devel::Probe](https://metacpan.org/pod/Devel::Probe)
- [Enbugger](https://metacpan.org/pod/Enbugger)
