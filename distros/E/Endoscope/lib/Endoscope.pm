package Endoscope;
$Endoscope::VERSION = '0.001';
# ABSTRACT: Dig into the guts of a live Perl program

use strict;
use warnings;

use feature qw(say);

use Carp;
our @CARP_NOT = qw(Devel::Optic);
use Scalar::Util qw(looks_like_number);

use Devel::Probe;
use Devel::Optic;

use constant {
    ALWAYS => 1,
};

sub new {
    my ($class, %options) = @_;

    my $self = {};

    $self = {
        optic => $options{optic} // Devel::Optic->new(uplevel => 2),
        monitor => sub {
            my ($file, $line, $query, $result) = @_;
            say STDERR "Endoscope: $file/$line/$query = $result";
        },
        probe => sub {
            my ($file, $line, $query) = @_;
            my $result;

            eval {
                $result = $self->{optic}->inspect($query);
                1;
            } or do {
                my $err = $@ || "zombie error";
                $result = $err;
            };

            $self->{monitor}->($file, $line, $query, $result);
        },
        views => {},
    };

    if (exists $options{monitor}) {
        $self->{monitor} = $options{monitor};
    }

    bless $self, $class;
}

sub apply {
    my ($self) = shift;

    my %views = %{ $self->{views} };
    if (!scalar keys %views) {
        Devel::Probe::remove();
        return;
    }

    Devel::Probe::install();
    Devel::Probe::trigger($self->{probe});
    for my $file (keys %views) {
        for my $line (keys %{ $views{$file} }) {
            my ($query, $type) = @{ $views{$file}->{$line} };
            Devel::Probe::add_probe($file, 0+$line, $type, $query);
        }
    }

    Devel::Probe::enable();
}

sub add {
    my ($self, $file, $line, $query, $always) = @_;
    if (!defined $file) {
        croak("Endoscope->add(file, line, query, ?always) must specify file");
    }

    if (!defined $line || !looks_like_number($line)) {
        croak("Endoscope->add(file, line, query, ?always) must specify line as a number");
    }

    if (!defined $query) {
        croak("Endoscope->add(file, line, query, ?always) must specify query");
    }

    $self->{views}->{$file}->{$line} = [$query, $always ? Devel::Probe::PERMANENT : Devel::Probe::ONCE ];
}

sub remove {
    my ($self, $file, $line) = @_;
    if (!defined $file) {
        croak("Endoscope->remove(file, line, query, ?always) must specify file");
    }

    if (!defined $line || !looks_like_number($line)) {
        croak("Endoscope->remove(file, line, query, ?always) must specify line as a number");
    }

    if (exists $self->{views}->{$file}) {
        delete $self->{views}->{$file}->{$line};
    }
}

sub clear {
    my ($self) = @_;
    $self->{views} = {};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Endoscope - Dig into the guts of a live Perl program

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Endoscope;
  my $scope = Endoscope->new();
  $scope->add(__FILE__, __LINE__ + 3, '$foo');
  $scope->apply();
  my $foo = "super cool data";
  my $bar = "baz"; # print: Endoscope: test.pl/6/$foo = 'super cool data (len 15)'

=head1 DESCRIPTION

L<Endoscope> is an L<endoscope|https://en.wikipedia.org/wiki/Endoscope>
for live Perl programs.

It provides dynamic run-time introspection of Perl variables at arbitrary
locations in the program. Think of it like inserting C<say Dumper($foo)> at
I<just> the right location in your code to figure out why it is misbehaving --
without restarting C<perl> or worrying whether C<$foo> contains gigabytes of
state.

It accomplishes this with low performance impact. See L</PERFORMANCE> for more
information on overhead. It is a major goal for this module and its
subcomponents to be suitable for always-on production usage.

This is a very powerful capability with significant implications for the
security of the data in a program's memory. As such, any usage of
C<Endoscope> should carefully guard access to the control or reporting
interfaces. See L</SECURITY> for a more comprehensive discussion.

=head1 NAME

Endoscope - inspect live Perl systems

=head1 METHODS

=head2 new

  my $e = Endoscope->new(%options);

Create a new Endoscope object. C<%options> may be empty, or contain any of the
following keys:

=over 4

=item C<monitor>

Subroutine to invoke with the result of the query. Use this to push to
a logging pipeline or other human-facing debugging tool.

Default implementation:

    sub {
        my ($file, $line, $query, $result) = @_;
        say STDERR "Endoscope: $file/$line/$query = $result";
    }

=back

=head2 add

  my $e = Endoscope->new();
  $e->add("foo.pl", 42, '$foo->[0]');

Add a L<Devel::Optic> query to the scope. Takes filename, line number, and
query as arguments.  An optional fourth argument, if true, will cause the query
to fire every time the codepath is executed, rather than just once. Use that
option with care.

=head2 remove

  $e->remove("foo.pl", 42);

Remove any query assigned to the file/line pair.

=head2 apply

  $e->apply();

C<apply> synchronizes the set of 'added' or 'removed' queries with the
underlying system, L<Devel::Probe>. Call this after 'adding' or 'removing'
queries, or to reset 'once' queries after they've fired. If Endoscope is
integrated with a web application, this would be called once per request early
in the request handling lifecycle.

=head2 clear

C<clear> removes all queries from settings. Call C<apply> to remove them for
real.

=head1 PERFORMANCE

C<Endoscope> and supporting libraries C<Devel::Probe> and C<Devel::Optic>
attempt to be suitable for usage in performance sensitive production
environments. However, 'performance sensitive' covers a wide range of
situations. As a rule of thumb, if the code you're querying strives to minimize
subroutine calls for performance reasons, it would be best to stick to the
default 'once' setting for queries, and be mindful of the amount of work
performed in the 'monitor'.

=head2 BENCHMARK

Benchmarking is very difficult, and for the sake of this document I'm going to
quote results from my laptop. The goal of this benchmark report is to give you
a general sense of how C<Endoscope> performs. Your milage may vary.

NOTE: all of the C<Endoscope> tests are conducted with at least one query
active and firing each time the associated code is executed. If no queries are
configured, C<Endoscope> has no measurable overhead. The recommended setup is
for C<Endoscope> to be installed and listening, and have the program expose
a privileged interface for system operators to set queries which execute once,
dump some information, and then remove themselves. This model of integration
should be suitable for all but the tightest performance requirements.

=head3 TEST SETUP

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

=head3 TEST PROGRAMS

Baseline program:

	use Mojolicious::Lite;

	get '/hello' => sub {
		my $c = shift;
		my $app = app;
		$c->render(text => "hello!\n");
	};

	app->start;

C<Endoscope> variant program:

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

These programs store 'app' into C<$app> in order to give C<Endoscope> a large structure to query.

The Mojo app is running in 'production' mode.

    $ perl test.pl daemon -m production

This avoids measuring the performance of printing logs to C<STDERR>.

The load generator is L<wrk2|https://github.com/giltene/wrk2>, invoked in the following way:

    $ wrk 'http://localhost:3000/hello' -R 2500 -d 60

=head4 HOW TO READ THE RESULTS

The test cases use a target request rate of 2500 RPS. This exceeds the baseline
single-core performance of Mojolicious on my laptop. As such, the latency
numbers look really high: we are saturating the test programs.

I did this because lower request rates, like 2000 RPS, resulted in
both test programs easily managing the request rates with average latencies in
the single-digit millisecond range. This demonstrated no clear relationship
between the two programs: sometimes the program that did strictly more work was
I<faster>, which is a sign of a broken benchmark.

Due to the saturation, the latency numbers are not very meaningful.

However, the request rate that the program manages to output in the face of
saturation is useful: the difference in RPS delivered by the baseline vs. the
Endoscope variant can be read as the "overhead" introduced by C<Endoscope>.

=head3 BASELINE

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

=head3 C<ENDOSCOPE> VARIANT

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

=head3 DISCUSSION

The baseline program delivered 2365 requests per second in the face of clients
demanding 2500 requests per second. The C<Endoscope> variant delivered 2174
requests per second, or 91.92% of baseline. In other words, C<Endoscope> in the
given configuration reduces capacity by about 8.1%.

8.1% can be seen as a lower bound on overhead with a query firing once per
request on saturated, CPU-bound Mojolicious web apps. Queries that fire more
than once per request, or which do expensive work while exporting data, may
have a higher impact. However, most real-world applications:

=over 2

=item *

Do not run at their 'red line' of capacity, and

=item *

Do significantly more work than render out "Hello World".

=back

So, you are encouraged to measure for yourself.

=head4 UNSATURATED

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

=head1 SECURITY

C<Endoscope> is a powerful tool for debugging running systems by inspecting
their memory. This means that anyone who is able to configure C<Endoscope>
queries and view their output can read the contents of nearly any variable
present in memory. As such, access to these capabilities should be carefully
guarded.

For example, if C<Endoscope> is integrated into a web framework and exposes
a special HTTP endpoint for configuring queries, that endpoint should only be
accessible from the host where the application is running, not externally.
Additionally, that HTTP endpoint should be gated by strong
authentication/authorization.

=head1 SEE ALSO

=over 4

=item *

L<Devel::Optic>

=item *

L<Devel::Probe>

=item *

L<Enbugger>

=back

=head1 AUTHOR

Ben Tyler <btyler@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ben Tyler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
