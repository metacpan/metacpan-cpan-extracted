use strict;
use Test::More (tests => 10);
use Test::Exception;
use lib "t/lib";
use Test::Google::Chart qw(have_connection);


{ # Pie
    my $chart = Google::Chart->new(
        type => "Pie",
        size => "400x300",
        data => [ 1, 2, 3, 4, 5 ],
    );

    ok( $chart );
    isa_ok( $chart, "Google::Chart" );

    isa_ok( $chart->type, "Google::Chart::Type::Pie" );

    is( $chart->size->width, 400 );
    is( $chart->size->height, 300 );

    my $uri = $chart->as_uri;
    note $uri;
    my %h = $uri->query_form;
    is( $h{cht}, "p" );
    is( $h{chs}, "400x300" );

    SKIP: {
        if (! have_connection()) {
            skip( "No connection to google charts API", 3 );
        }
        my $filename = 't/foo.png';

        unlink $filename;

        ok(! -f $filename);

        lives_ok { $chart->render_to_file( filename => $filename ) } "render_to_file($filename) should work";

        ok(-f $filename );
    }
}

