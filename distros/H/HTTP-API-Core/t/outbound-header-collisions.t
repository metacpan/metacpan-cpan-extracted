use strict;
use warnings;
use Test::More;
use HTTP::API::Core;

sub caught_error {
    my ($code) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    return $error;
}

sub ok_transport {
    return { status => 200, headers => {}, content => '{}' };
}

{
    my $calls = 0;
    my $error = caught_error(sub {
        HTTP::API::Core->new(
            base_url  => 'https://api.example.test',
            headers   => {
                Authorization => 'Bearer first',
                authorization => 'Bearer second',
            },
            transport => sub { $calls++; return ok_transport() },
        );
    });
    like $error, qr/conflicting case-insensitive header values: authorization/,
        'conflicting case-insensitive default Authorization is rejected';
    is $calls, 0, 'invalid defaults never dispatch a request';
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url  => 'https://api.example.test',
        transport => sub { $calls++; return ok_transport() },
    );
    my $error = caught_error(sub {
        $api->get('/secret', headers => {
            Authorization => 'Bearer first',
            authorization => 'Bearer second',
        });
    });
    like $error, qr/conflicting case-insensitive header values: authorization/,
        'conflicting request Authorization values are rejected';
    is $calls, 0, 'ambiguous credentials never reach transport';
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url  => 'https://api.example.test',
        transport => sub { $calls++; return ok_transport() },
    );
    my $error = caught_error(sub {
        $api->post('/payment', headers => {
            'Idempotency-Key' => 'purchase-A',
            'idempotency-key' => 'purchase-B',
        });
    });
    like $error, qr/conflicting case-insensitive header values: idempotency-key/,
        'conflicting idempotency headers are rejected';
    is $calls, 0, 'ambiguous idempotency values never reach transport';
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url  => 'https://api.example.test',
        headers   => { Authorization => 'Bearer default' },
        hooks     => { before_request => sub {
            $_[0]{headers}{authorization} = 'Bearer hook';
        } },
        transport => sub { $calls++; return ok_transport() },
    );
    my $error = caught_error(sub { $api->get('/hook') });
    like $error, qr/conflicting case-insensitive header values: authorization/,
        'hook mutations introducing conflicting header spelling are rejected';
    is $calls, 0, 'hook-created ambiguity is rejected before transport';
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url  => 'https://api.example.test',
        transport => sub { $calls++; return ok_transport() },
    );
    my $error = caught_error(sub {
        $api->get('/mixed-defined', headers => {
            'X-Token' => undef,
            'x-token' => 'token',
        });
    });
    like $error, qr/conflicting case-insensitive header values: x-token/,
        'defined/undefined duplicate header values are conflicting';
    is $calls, 0, 'defined/undefined ambiguity does not reach transport';
}

{
    my @seen;
    my $api = HTTP::API::Core->new(
        base_url  => 'https://api.example.test',
        headers   => { Authorization => 'Bearer default' },
        transport => sub {
            push @seen, { %{ $_[2]{headers} } };
            return ok_transport();
        },
    );
    is $api->get('/override', headers => {
        authorization => 'Bearer override',
    })->status, 200, 'request-level authorization override still succeeds';
    is $seen[-1]{authorization}, 'Bearer override',
        'request-level authorization wins over default with other spelling';
    ok !exists($seen[-1]{Authorization}),
        'default spelling is removed on request override';

    is $api->get('/matching', headers => {
        Authorization => 'Bearer same',
        authorization => 'Bearer same',
    })->status, 200, 'identical case-insensitive duplicates are accepted';
    is $seen[-1]{authorization}, 'Bearer same',
        'matching duplicates use a deterministic surviving spelling';
    ok !exists($seen[-1]{Authorization}),
        'matching request spellings collapse to a single key';

    is $api->get('/next')->status, 200,
        'a subsequent request uses unchanged client headers';
    is $seen[-1]{Authorization}, 'Bearer default',
        'default credential is unchanged by previous request';
}

{
    my @seen;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        headers => { 'X-Flag' => undef, 'x-flag' => undef },
        transport => sub {
            push @seen, { %{ $_[2]{headers} } };
            return ok_transport();
        },
    );
    is $api->get('/undefined')->status, 200,
        'matching undefined header values are permitted';
    ok exists($seen[-1]{'X-Flag'}) && exists($seen[-1]{'x-flag'}),
        'matching undefined defaults retain prior transport representation';
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        hooks => { before_request => sub {
            $_[0]{headers}{'X-Test'} = 'same';
            $_[0]{headers}{'x-test'} = 'same';
        } },
        transport => sub { $calls++; return ok_transport() },
    );
    is $api->get('/hook-matching')->status, 200,
        'matching duplicate values added by hooks are accepted';
    is $calls, 1, 'valid duplicate values dispatch once';
}

done_testing;
