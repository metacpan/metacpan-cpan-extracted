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
}

done_testing;
