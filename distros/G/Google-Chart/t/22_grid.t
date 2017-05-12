use strict;
use Test::More (tests => 8);
use Test::Exception;

BEGIN
{
    use_ok("Google::Chart::Grid");
    use_ok("Google::Chart");
}

{
    my $grid = Google::Chart::Grid->new(
        x_step_size => 20,
        y_step_size => 40,
    );

    ok($grid);
    isa_ok($grid, "Google::Chart::Grid");
    my $query = $grid->as_query;
    note($query);
    is( $query, "chg=20%2C40%2C1%2C1" );
}
{
    my $graph = Google::Chart->new(
        type => 'Line',
        size => '300x300',
        data => {
            module => 'Extended',
            args => {
                dataset => [[180,-67.5,4.6],[-20,10,130]],
                min_value => -100,
                max_value => 200,
            }
        },
        axis => [
            {
                location => 'x',
                labels => [1, 2, 3],
            },
            {
                location => 'y',
                labels => [-100,0,100,200],
            },
        ],
        grid => {
            x_step_size => 50,
            y_step_size => 33.3,
        },
        color => ['ff0000', '00ffff'],
        legend => ['data1', 'data2'],
    );
    ok($graph);
    isa_ok($graph, 'Google::Chart');
    my $uri = $graph->as_uri;
    note ($uri);
    my %h = $uri->query_form;
    is( $h{chg}, '50,33.3,1,1' );
}
