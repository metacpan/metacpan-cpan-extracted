use strict;
use Test::More (tests => 13);

BEGIN
{
    use_ok("Google::Chart::Marker");
}

{
    my $marker = Google::Chart::Marker->new();
    ok($marker);
    isa_ok($marker, "Google::Chart::Marker");

    is( $marker->as_query, "chm=o%2C000000%2C0%2C-1%2C5%2C0" );
}

{
    my $data = Google::Chart::Marker::Item->new(
        marker_type => 'h',
        color => '999999',
        datapoint => '0.3',
        size => '0.5',
    );
    ok($data);
    isa_ok($data, 'Google::Chart::Marker::Item');
    is ($data->as_string, 'h,999999,0,0.3,0.5,0');
}

{
    my $marker = Google::Chart::Marker->new(
        markerset =>  [ {
            marker_type => 'h',
            color => '999999',
            datapoint => 0.3,
            size => 0.5,
        } ]
    );
    ok($marker);
    isa_ok($marker, "Google::Chart::Marker");

    is( $marker->as_query, "chm=h%2C999999%2C0%2C0.3%2C0.5%2C0" );
}
{
    my $marker = Google::Chart::Marker->new(
        markerset =>  {
            marker_type => 'h',
            color => '999999',
            datapoint => 0.3,
            size => 0.5,
        }
    );
    ok($marker);
    isa_ok($marker, "Google::Chart::Marker");

    is( $marker->as_query, "chm=h%2C999999%2C0%2C0.3%2C0.5%2C0" );
}