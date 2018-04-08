use warnings;
use strict;
use lib 't';
use share;

my $Response;

my $server = JSON::RPC2::Server->new();
my $client = JSON::RPC2::Client->new();
my @t;
my @Called;
my ($json_request, @call);

$server->register('a',              sub{ return "a $_[0]" });
$server->register('a_err',          sub{ return undef, 1, "a_err $_[0]" });
$server->register_named('b',        sub{ my %p=@_; return "b $p{first}" });
$server->register_named('b_err',    sub{ my %p=@_; return undef, 2, "b_err $p{first}" });
$server->register_nb('c',           \&c);
$server->register_nb('c_err',       \&c_err);
$server->register_named_nb('d',     \&d);
$server->register_named_nb('d_err', \&d_err);

$server->register('e',              sub{ push @Called, 'e'; return });
$server->register_named('f',        sub{ push @Called, 'f'; return });
$server->register_nb('g',           \&g);
$server->register_named_nb('h',     \&h);

sub c {
    my ($cb, @p) = @_;
    push @t, EV::timer(0.01, 0, sub {
        $cb->("c $p[0]");
    });
}
sub c_err {
    my ($cb, @p) = @_;
    push @t, EV::timer(0.01, 0, sub {
        $cb->(undef, 3, "c_err $p[0]");
    });
}
sub d {
    my ($cb, %p) = @_;
    push @t, EV::timer(0.03, 0, sub {
        $cb->("d $p{first}");
    });
}
sub d_err {
    my ($cb, %p) = @_;
    push @t, EV::timer(0.03, 0, sub {
        $cb->(undef, 4, "d_err $p{first}", 'extra data');
    });
}
sub g {
    my ($cb, @p) = @_;
    push @t, EV::timer(0.02, 0, sub {
        push @Called, 'g';
        $cb->();
    });
}
sub h {
    my ($cb, %p) = @_;
    push @t, EV::timer(0.04, 0, sub {
        push @Called, 'h';
        $cb->();
    });
}


# - several call -> several replies
($json_request, @call) = $client->batch(
    $client->call('a', 42),
    $client->call_named('a', first => 42),
    $client->call('a_err', 42),
    $client->call('b', 42),
    $client->call_named('b', first => 42),
    $client->call('b_err', 42),
);
execute($json_request);
is 0+@{$Response}, 6,
    'batch 6 calls';
is $Response->[0]{result}, 'a 42',
    'a';
is $Response->[1]{error}{code}, -32602;
is $Response->[1]{error}{message}, 'This method expect positional params.';
is $Response->[2]{error}{code}, 1,
    'a_err';
is $Response->[2]{error}{message}, 'a_err 42';
is $Response->[3]{error}{code}, -32602,
    'b';
is $Response->[3]{error}{message}, 'This method expect named params.';
is $Response->[4]{result}, 'b 42';
is $Response->[5]{error}{code}, -32602,
    'b_err';
is $Response->[5]{error}{message}, 'This method expect named params.';

# - several notify -> empty reply
($json_request, @call) = $client->batch(
    $client->notify('e', 42),
    $client->notify_named('f', first => 42),
);
execute($json_request);
is $Response, q{},
    'batch 2 notify';
is_deeply \@Called, ['e','f'];

# - several notify and bad notify -> several replies
($json_request, @call) = $client->batch(
    $client->notify('e', 42),
    $client->notify_named('e', first => 42),
    $client->notify('f', 42),
    $client->notify_named('f', first => 42),
);
execute($json_request);
is 0+@{$Response}, 2,
    'batch 2 notify and 2 bad notify';
is $Response->[0]{error}{code}, -32602;
is $Response->[0]{error}{message}, 'This method expect positional params.';
is $Response->[1]{error}{code}, -32602;
is $Response->[1]{error}{message}, 'This method expect named params.';

# - mix of call and notify -> replies only for calls
($json_request, @call) = $client->batch(
    $client->call('a_err', 42),
    $client->notify('e', 42),
    $client->call_named('b', first => 42),
    $client->notify_named('f', first => 42),
);
execute($json_request);
is 0+@{$Response}, 2,
    'batch 2 call and 2 notify';
is $Response->[0]{error}{code}, 1,
    'a_err';
is $Response->[0]{error}{message}, 'a_err 42';
is $Response->[1]{result}, 'b 42';

# - mix of async call and notify -> order of replies not match order of calls
SKIP: {
    skip 'module EV required', 1 unless eval { require EV };

    ($json_request, @call) = $client->batch(
        $client->call_named('d', first => 99),      # 0.03 sec
        $client->notify_named('h', first => 42),    # 0.04 sec
        $client->call('c_err', 42),                 # 0.01 sec
        $client->call_named('d', first => 42),      # 0.03 sec
        $client->notify('g', 42),                   # 0.02 sec
    );
    execute($json_request);
    EV::run(EV::RUN_ONCE()) while !$Response;
    is 0+@{$Response}, 3,
        'async batch 3 call and 2 notify';
    is $Response->[0]{error}{code}, 3,
        'c_err';
    is $Response->[0]{error}{message}, 'c_err 42';
    is $Response->[1]{result}, 'd 42',
        'd';
    is $Response->[2]{result}, 'd 99',
        'd';
    is_deeply \@Called, ['g','h'],
        'g, h';
}


done_testing();


sub execute {
    my ($json) = @_;
    $Response = undef;
    @Called = ();
    $server->execute($json, sub { $Response = $_[0] ? decode_json($_[0]) : $_[0] });
}
