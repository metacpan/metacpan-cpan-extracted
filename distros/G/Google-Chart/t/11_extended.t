use strict;
use Test::More (tests => 11);
use Test::Exception;

BEGIN
{
    use_ok("Google::Chart::Data::Extended");
}

{
    my $data = Google::Chart::Data::Extended->new(
        max_value => 150,
        dataset => [ 1.0, 1.2, 1.3, 50, 100 ],
    );

    ok($data);
    isa_ok($data, "Google::Chart::Data::Extended");
    my $query = $data->as_query;
    note($query);
    is( $query, "chd=e%3AAbAgAjVVqq" );
}
{
    my $data = Google::Chart::Data::Extended->new(
        max_value => 150,
        dataset => [
            [ 1.0, 1.2, 1.3, 50, 100 ],
            [ 100, 50, 1.3, 1.2, 1.0 ],
        ],
    );

    ok($data);
    isa_ok($data, "Google::Chart::Data::Extended");
    my $query = $data->as_query;
    note($query);
    is( $query, "chd=e%3AAbAgAjVVqq%2CqqVVAjAgAb" );
}
{
    my $data = Google::Chart::Data::Extended->new(
        max_value => 150,
        min_value => -50,
        dataset => [
            [ -10, -40, 10, 70, 100 ],
            [ 100, 50, -0.5, 2, -35.7 ],
        ],
    );

    ok($data);
    isa_ok($data, "Google::Chart::Data::Extended");
    my $query = $data->as_query;
    note($query);
    is( $query, "chd=e%3AMzDMTMmZv.%2Cv.f.P1QoEk");
}

{
    dies_ok { Google::Chart::Data::Extended->new([ 'A' ]) } "bad args"
}
