use strict;
use warnings;
use blib;

use Test::More tests => 43;

use constant valid_mfrom_identity   => ( identity   => 'fred@example.com' );
use constant valid_ip_address       => ( ip_address => '192.168.0.1' );


#### Class Compilation ####

BEGIN { use_ok('Mail::SPF::Request') }


#### Basic Instantiation ####

{
    my $request = eval { Mail::SPF::Request->new(
        versions    => [1, 2],
        scope       => 'mfrom',
        identity    => 'fred@example.com',
        ip_address  => '192.168.0.1',
        helo_identity
                    => 'mta.example.com'
    ) };

    $@ eq '' and isa_ok($request, 'Mail::SPF::Request', 'Basic request object')
        or BAIL_OUT("Basic request instantiation failed: $@");

    # Have options been interpreted correctly?
    is_deeply([$request->versions], [1, 2],             'Basic request versions()');
    is($request->scope,             'mfrom',            'Basic request scope()');
    is($request->authority_domain,  'example.com',      'Basic request authority_domain()');
    is($request->identity,          'fred@example.com', 'Basic request identity()');
    is($request->domain,            'example.com',      'Basic request domain()');
    is($request->localpart,         'fred',             'Basic request localpart()');
    my $ip_address = $request->ip_address;
    isa_ok($ip_address,             'NetAddr::IP',      'Basic request ip_address()');
    is($ip_address,                 '192.168.0.1/32',   'Basic request ip_address()');
    is($ip_address->version,        4,                  'Basic request ip_address() IP version');
    my $ip_address_v6 = $request->ip_address_v6;
    isa_ok($ip_address_v6,          'NetAddr::IP',      'Basic request ip_address_v6()');
    is($ip_address_v6, NetAddr::IP->new('::ffff:192.168.0.1'), 'Basic request ip_address_v6()');
    is($ip_address_v6->version,     6,                  'Basic request ip_address_v6() IP version');
    is($request->helo_identity,     'mta.example.com',  'Basic request helo_identity()');

    # Request object cloning:
    my $request_clone = eval { $request->new( ip_address => '192.168.0.254' ) };
    isa_ok($request_clone, 'Mail::SPF::Request', 'Clone request object');
    is($request_clone->identity,    'fred@example.com', 'Clone request inherited identity()');
    is($request_clone->ip_address,  '192.168.0.254/32', 'Clone request override ip_address()');
}


#### Minimally Parameterized MAIL FROM Request ####

{
    my $request = eval { Mail::SPF::Request->new(
        identity    => 'fred@example.com',
        ip_address  => '192.168.0.1'
    ) };

    $@ eq '' and isa_ok($request, 'Mail::SPF::Request', 'Minimal MAIL FROM request object')
        or BAIL_OUT("Minimal MAIL FROM request instantiation failed: $@");

    # Have omitted options been deduced correctly?
    is_deeply([$request->versions], [1, 2],             'Minimal MAIL FROM request versions()');
    is($request->scope,             'mfrom',            'Minimal MAIL FROM request scope()');
    is($request->authority_domain,  'example.com',      'Minimal MAIL FROM request authority_domain()');
    is($request->helo_identity,     undef,              'Minimal MAIL FROM request helo_identity()');
}


#### Minimally Parameterized HELO Request ####

{
    my $request = eval { Mail::SPF::Request->new(
        scope       => 'helo',
        identity    => 'mta.example.com',
        valid_ip_address
    ) };

    $@ eq '' and isa_ok($request, 'Mail::SPF::Request', 'Minimal HELO request object')
        or BAIL_OUT("Minimal HELO request instantiation failed: $@");

    # Have omitted options been deduced correctly?
    is_deeply([$request->versions], [1],                'Minimal HELO request versions()');
    is($request->authority_domain,  'mta.example.com',  'Minimal HELO request authority_domain()');
    is($request->localpart,         'postmaster',       'Minimal HELO request default localpart()');
    is($request->helo_identity,     'mta.example.com',  'Minimal HELO request helo_identity()');
}


#### Versions Validation ####

{
    my $request;

    $request = Mail::SPF::Request->new(
        versions    => 1,
        valid_mfrom_identity,
        valid_ip_address
    );
    is_deeply([$request->versions], [1],                'versions => $string supported');

    eval { Mail::SPF::Request->new(
        versions    => {},  # Illegal versions option type!
        valid_mfrom_identity,
        valid_ip_address
    ) };
    isa_ok($@, 'Mail::SPF::EInvalidOptionValue',        'versions => $non_string_or_array illegal');

    eval { Mail::SPF::Request->new(
        versions    => [1, 666],  # Illegal version number!
        valid_mfrom_identity,
        valid_ip_address
    ) };
    isa_ok($@, 'Mail::SPF::EInvalidOptionValue',        'Detect illegal versions');

    $request = Mail::SPF::Request->new(
        versions    => [1, 2],
        scope       => 'helo',
        identity    => 'mta.example.com',
        valid_ip_address
    );
    is_deeply([$request->versions], [1],                'Drop versions irrelevant for scope');
}


#### Scope Validation ####

{
    eval { Mail::SPF::Request->new(
        scope       => 'foo',
        valid_mfrom_identity,
        valid_ip_address
    ) };
    isa_ok($@, 'Mail::SPF::EInvalidScope',              'Detect invalid scope');

    eval { Mail::SPF::Request->new(
        versions    => 1,
        scope       => 'pra',
        valid_mfrom_identity,
        valid_ip_address
    ) };
    isa_ok($@, 'Mail::SPF::EInvalidScope',              'Detect invalid scope for versions');
}


#### Identity Validation ####

{
    my $request;

    eval { Mail::SPF::Request->new(
        valid_ip_address
    ) };
    isa_ok($@, 'Mail::SPF::EOptionRequired',            'Detect missing identity option');

    $request = Mail::SPF::Request->new(
        scope       => 'mfrom',
        identity    => 'mta.example.com',  # Empty MAIL FROM, supply HELO domain.
        valid_ip_address
    );
    is($request->domain,            'mta.example.com',  'Extract domain from identity correctly');
    is($request->localpart,         'postmaster',       'Default "postmaster" localpart');
}


#### IP Address Validation ####

{
    my $request;

    eval { Mail::SPF::Request->new(
        valid_mfrom_identity
    ) };
    isa_ok($@, 'Mail::SPF::EOptionRequired',            'Detect missing ip_address option');

    my $ip_address = NetAddr::IP->new('192.168.0.1');
    $request = Mail::SPF::Request->new(
        valid_mfrom_identity,
        ip_address  => $ip_address
    );
    is($request->ip_address,        $ip_address,        'Accept NetAddr::IP object for ip_address');

    $request = Mail::SPF::Request->new(
        valid_mfrom_identity,
        ip_address  => '::ffff:192.168.0.1'
    );
    is($request->ip_address,        '192.168.0.1/32',   'Treat IPv4-mapped IPv6 address as IPv6 address');
}


#### Custom Request State ####

{
    my $request = Mail::SPF::Request->new(
        valid_mfrom_identity,
        valid_ip_address
    );

    is($request->state('uninitialized'), undef,         'Read uninitialized state field');

    $request->state('foo', 'bar');
    is($request->state('foo'),      'bar',              'Write and read state field');

    my $request_clone = $request->new();  # Clone request object.
    $request_clone->state('foo', 'boo');
    is($request->state('foo'),      'bar',              'Original state unaffected when modifying clone state');
}
