use strict;
use Test::More (tests => 10);
use Test::Exception;

BEGIN
{
    use_ok("Google::Chart");
    use_ok("Google::Chart::Fill::Solid");
}

{
    my $fill = Google::Chart::Fill::Solid->new(
        color => 'ffccff',
        target => 'bg',
    );

    is( $fill->as_query, "chf=bg%2Cs%2Cffccff", "solid fill creates proper query" );
}

{
    my $chart = Google::Chart->new(
        type => "Line",
        size => "400x300",
        data => [ 1, 2, 3, 4, 5 ],
        fill => {
            module => "LinearGradient",
            args   => {
                target => "bc",
                angle  => 0,
                color1  => "ffccff",
                color2  => "ffffff",
            }
        },
    );

    ok( $chart );
    isa_ok( $chart, "Google::Chart" );

    isa_ok( $chart->type, "Google::Chart::Type::Line" );

    is( $chart->size->width, 400 );
    is( $chart->size->height, 300 );

    my $uri = $chart->as_uri;
    note $uri;
    my %h = $uri->query_form;
    is( $h{cht}, "lc" );
    is( $h{chs}, "400x300" );
}
