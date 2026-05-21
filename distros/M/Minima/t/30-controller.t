use v5.40;
use Test2::V0;

use Hash::MultiValue;
use JSON;
use Minima::App;
use Minima::Controller;

use utf8;

# Basic response
{
    my $app = Minima::App->new;
    my $c = Minima::Controller->new(
        app => $app,
        route => { },
    );

    my $response = $c->hello;
    is( ref $response, ref [], 'returns array ref' );
    is( scalar @$response, 3, 'returns valid array ref' );
    is( $response->[0], 200, 'returns valid response code' );
}

# Request decoding
{
    my $fake_env = {
        'plack.request.merged' => Hash::MultiValue->new(
            "\xE8\x8B\x97\xE5\xAD\x97" =>
            "\xE3\x83\x86\xE3\x82\xB5\xE3\x83\xAA\xE3\x83\xB3",
        ),
    };
    my $config = { };
    my $app = Minima::App->new(
        environment => $fake_env,
        configuration => $config,
    );
    my $c = Minima::Controller->new(
        app => $app,
        route => {},
    );

    my @kv = %{ $c->params };

    like(
        length $kv[0],
        2,
        'decodes keys properly',
    );

    like(
        length $kv[1],
        4,
        'decodes values properly',
    );

    $config->{request_encoding} = 'ascii';
    $c = Minima::Controller->new(
        app => $app,
        route => {},
    );

    @kv = %{ $c->params };

    like(
        length $kv[0],
        6,
        'respects ascii keys',
    );

    like(
        length $kv[1],
        12,
        'respects ascii values',
    );

    # _decode doesn't crash on undef
    is( $c->_decode(undef), undef, '_decode handles undef' );
}

# Utils
{
    my $env = { K => 1 };
    my $app = Minima::App->new(environment => $env);
    my $c = Minima::Controller->new(app => $app);

    # print_env in production
    $ENV{PLACK_ENV} = 'deployment';
    is(
        $c->print_env->[0],
        302,
        'print_env redirects when in production'
    );

    # print_env in development
    delete $ENV{PLACK_ENV};
    like(
        $c->print_env->[2][0],
        qr/K\s*=>\s*1/,
        'print_env produces proper output'
    );

    # dd
    like(
        $c->dd([0])->[2][0],
        qr/\[\s*0\s*]/,
        'dd produces proper output'
    );
}

# Trimming params
{
    my $fake_env = {
        'plack.request.merged' => Hash::MultiValue->new(
            name => '  Minima ',
            password => ' perlclass ',
            raw_field => ' raw ',
            multi => ' 0 ',
            multi => ' 1 ',
            array => [ ' 0 ', ' 1 ' ],
            hash => { key => ' value ' },
            undef => undef,
            undef_a => [ undef ],
        )
    };
    my $app = Minima::App->new(environment => $fake_env);
    my $c = Minima::Controller->new(app => $app);

    my $params = $c->trimmed_params({ exclude => [ 'password', qr/^raw/ ] });

    is( $params->{name}, 'Minima', 'trims scalar' );
    is( $params->{password}, ' perlclass ', 'excludes string key' );
    is( $params->{raw_field}, ' raw ', 'excludes key by regex reference' );
    is( [ $params->get_all('multi') ], [0,1], 'trims values of multi-keys' );
    is( $params->{array}[1], 1, 'trims elements of array values' );
    is( $params->{hash}{key}, ' value ', 'leaves hash refs untouched' );

    # no exclusions
    $params = $c->trimmed_params;
    is( $params->{password}, 'perlclass', 'works on everything if needed' );

    # scalar reference is not a valid exclusion
    my $pass = 'password';
    $params = $c->trimmed_params({ exclude => [ \$pass ] });
    is( $params->{password}, 'perlclass', 'scalar ref is not a valid exclusion' );
}

# UTF-8 JSON decoding
{
    my $body = encode_json({ word => 'órgão' });
    open my $fh, '<', \$body;
    my $env = {
        'psgi.input'     => $fh,
        'CONTENT_LENGTH' => length($body),
        'CONTENT_TYPE'   => 'application/json',
    };
    my $app = Minima::App->new(environment => $env);
    my $c   = Minima::Controller->new(app => $app);

    my $data = $c->json_body;
    is( $data->{word}, 'órgão', 'decodes UTF-8 JSON correctly' );
}

# Wrong content-type
{
    my $body = '{}'; open my $fh, '<', \$body;
    my $env = {
        'psgi.input'     => $fh,
        'CONTENT_LENGTH' => length($body),
        'CONTENT_TYPE'   => 'text/plain',
    };
    my $app = Minima::App->new(environment => $env);
    my $c   = Minima::Controller->new(app => $app);

    is( $c->json_body, undef, 'wrong content-type returns undef' );

    delete $env->{CONTENT_TYPE};
    is( $c->json_body, undef, 'inexisting content-type returns undef' );
}

# Broken content-length
{
    my $body = '{}'; open my $fh, '<', \$body;
    my $env = {
        'psgi.input'     => $fh,
        'CONTENT_LENGTH' => 662,
        'CONTENT_TYPE'   => 'application/json',
    };
    my $app = Minima::App->new(environment => $env);

    like(
        dies { my $c   = Minima::Controller->new(app => $app) },
        qr/content-length/i,
        'dies on broken content-length'
    );
}

# Broken body
{
    my $env = { CONTENT_TYPE => 'application/json' };
    my $app = Minima::App->new(environment => $env);
    my $c   = Minima::Controller->new(app => $app);

    is( $c->json_body, undef, 'no body returns undef' );
}

# Invalid JSON
{
    my $body = '{broken:json}'; open my $fh, '<', \$body;
    my $env = {
        'psgi.input'     => $fh,
        'CONTENT_LENGTH' => length($body),
        'CONTENT_TYPE'   => 'application/json',
    };
    my $app = Minima::App->new(environment => $env);
    my $c   = Minima::Controller->new(app => $app);

    is( $c->json_body, undef, 'invalid JSON returns undef' );
}

# Flash messages
{
    my $env = {};
    my $app = Minima::App->new(environment => $env);
    my $c   = Minima::Controller->new(app => $app);

    # no session
    like(
        dies { $c->flash(a => 0) },
        qr/requires session/i,
        'fails if no session is present'
    );

    # enable sessions
    my $session = {};
    my $options = { no_store => 1 };
    $env->{'psgix.session'} = $session;
    $env->{'psgix.session.options'} = $options;

    # empty
    is( $c->flash, undef, 'pops undef when no messages exist');
    is(
        $options->{no_store},
        1,
        'empty pop does not force session storage'
    );

    # add messages
    $c->flash(a => 1);
    is(
        $session->{Minima::Controller::k_FLASH},
        { a => [ 1 ] },
        'stores flash messages successfully',
    );
    ok(
        !exists $options->{no_store},
        'adding flash marks session for storage',
    );

    $c->flash(a => 2);
    $c->flash(b => 3);

    is(
        scalar(keys $session->{Minima::Controller::k_FLASH}->%*),
        2,
        'handles grouping keys'
    );

    is(
        scalar($session->{Minima::Controller::k_FLASH}{a}->@*),
        2,
        'handles grouping values'
    );

    # remove messages
    $options->{no_store} = 1;
    $c->flash;
    is(
        $session->{Minima::Controller::k_FLASH},
        undef,
        'removes flash messages properly'
    );
    ok(
        !exists $options->{no_store},
        'removing marks session for storage',
    );

    # no options available
    delete $env->{'psgix.session.options'};
    $c->flash(c => 4);
    is(
        $session->{Minima::Controller::k_FLASH},
        { c => [ 4 ] },
        'stores messages even without options object'
    );
    $c->flash;
    is(
        $session->{Minima::Controller::k_FLASH},
        undef,
        'removes messages even without options object'
    );
}

done_testing;
