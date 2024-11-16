use v5.40;
use Test2::V0;

use Hash::MultiValue;
use Minima::App;
use Minima::Controller;

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
}

done_testing;
