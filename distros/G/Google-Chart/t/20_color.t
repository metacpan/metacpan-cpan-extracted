use strict;
use Test::More (tests => 14);
use Test::Exception;

BEGIN
{
    use_ok("Google::Chart::Color");
    use_ok("Google::Chart");
}

{
    my $color = Google::Chart::Color->new(
        values => ['000000','ff0000'],
    );

    ok($color);
    isa_ok($color, "Google::Chart::Color");
    my $query = $color->as_query;
    note($query);
    is( $query, "chco=000000%2Cff0000" );
}
{
    my $color = Google::Chart::Color->new(
        values => '000000',
    );

    ok($color);
    isa_ok($color, "Google::Chart::Color");
    my $query = $color->as_query;
    note($query);
    is( $query, "chco=000000" );
}

{
    my $graph = Google::Chart->new(
        type => 'Line',
        size => '300x300',
        data => [20, 40, 90],
        axis => [
            {
                location => 'x',
                labels => [1, 2, 3],
            },
        ],
        color => 'ff0000'
    );
    ok($graph);
    isa_ok($graph, 'Google::Chart');
    my $uri = $graph->as_uri;
    note ($uri);
    my %h = $uri->query_form;
    is( $h{chco}, 'ff0000' );
}
{
    my $graph = Google::Chart->new(
        type => 'Line',
        size => '300x300',
        data => [[20, 40, 90], [100, 70, 20]],
        axis => [
            {
                location => 'x',
                labels => [1, 2, 3],
            },
            {
                location => 'y',
                labels => [0,25,50,75,100],
            },
        ],
        color => ['ff0000', '00ffff'],
    );
    ok($graph);
    isa_ok($graph, 'Google::Chart');
    my $uri = $graph->as_uri;
    note ($uri);
    my %h = $uri->query_form;
    is( $h{chco}, 'ff0000,00ffff' );
}
