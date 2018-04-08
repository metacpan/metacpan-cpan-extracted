use warnings;
use strict;
use lib 't';
use share;

my $Response;

my $server = JSON::RPC2::Server->new();
my $client = JSON::RPC2::Client->new();
my @t;
my $Called;

$server->register('a',              sub{ return "a $_[0]" });
$server->register('a_err',          sub{ return undef, 1, "a_err $_[0]" });
$server->register_named('b',        sub{ my %p=@_; return "b $p{first}" });
$server->register_named('b_err',    sub{ my %p=@_; return undef, 2, "b_err $p{first}" });
$server->register_nb('c',           \&c);
$server->register_nb('c_err',       \&c_err);
$server->register_named_nb('d',     \&d);
$server->register_named_nb('d_err', \&d_err);
$server->register('e',              sub{ $Called='e'; return });
$server->register_named('f',        sub{ $Called='f'; return });

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
    push @t, EV::timer(0.01, 0, sub {
        $cb->("d $p{first}");
    });
}
sub d_err {
    my ($cb, %p) = @_;
    push @t, EV::timer(0.01, 0, sub {
        $cb->(undef, 4, "d_err $p{first}", 'extra data');
    });
}


execute($client->call('a', 42));
is $Response->{result}, 'a 42',
    'a';
execute($client->call_named('a', first => 42));
is $Response->{error}{code}, -32602;
is $Response->{error}{message}, 'This method expect positional params.';

execute($client->call('a_err', 42));
is $Response->{error}{code}, 1,
    'a_err';
is $Response->{error}{message}, 'a_err 42';
execute($client->call_named('a_err', first => 42));
is $Response->{error}{code}, -32602;
is $Response->{error}{message}, 'This method expect positional params.';

execute($client->call('b', 42));
is $Response->{error}{code}, -32602,
    'b';
is $Response->{error}{message}, 'This method expect named params.';
execute($client->call_named('b', first => 42));
is $Response->{result}, 'b 42';

execute($client->call('b_err', 42));
is $Response->{error}{code}, -32602,
    'b_err';
is $Response->{error}{message}, 'This method expect named params.';
execute($client->call_named('b_err', first => 42));
is $Response->{error}{code}, 2;
is $Response->{error}{message}, 'b_err 42';


SKIP: {
    skip 'module EV required', 1 unless eval { require EV };

    execute($client->call('c', 42));
    EV::run(EV::RUN_ONCE()) while !$Response;
    is $Response->{result}, 'c 42',
        'c';
    execute($client->call_named('c', first => 42));
    is $Response->{error}{code}, -32602;
    is $Response->{error}{message}, 'This method expect positional params.';

    execute($client->call('c_err', 42));
    EV::run(EV::RUN_ONCE()) while !$Response;
    is $Response->{error}{code}, 3,
        'c_err';
    is $Response->{error}{message}, 'c_err 42';
    execute($client->call_named('c_err', first => 42));
    is $Response->{error}{code}, -32602;
    is $Response->{error}{message}, 'This method expect positional params.';

    execute($client->call('d', 42));
    is $Response->{error}{code}, -32602,
        'd';
    is $Response->{error}{message}, 'This method expect named params.';
    execute($client->call_named('d', first => 42));
    EV::run(EV::RUN_ONCE()) while !$Response;
    is $Response->{result}, 'd 42';

    execute($client->call('d_err', 42));
    is $Response->{error}{code}, -32602,
        'd_err';
    is $Response->{error}{message}, 'This method expect named params.';
    execute($client->call_named('d_err', first => 42));
    EV::run(EV::RUN_ONCE()) while !$Response;
    is $Response->{error}{code}, 4;
    is $Response->{error}{message}, 'd_err 42';
}

execute($client->notify('e'));
is $Response, q{},
    'e';
is $Called, 'e';
execute($client->notify_named('e', first => 42));
is $Response->{error}{code}, -32602;
is $Response->{error}{message}, 'This method expect positional params.';
ok !$Called;

execute($client->notify('f', 42));
is $Response->{error}{code}, -32602,
    'f';
is $Response->{error}{message}, 'This method expect named params.';
ok !$Called;
execute($client->notify_named('f'));
is $Response, q{};
is $Called, 'f';


done_testing();


sub execute {
    my ($json) = @_;
    $Response = undef;
    $Called = undef;
    $server->execute($json, sub { $Response = $_[0] ? decode_json($_[0]) : $_[0] });
}
