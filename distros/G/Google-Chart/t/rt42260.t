use strict;
use Test::More (tests => 2);
use Google::Chart;
use Google::Chart::Data::Simple;
use Google::Chart::Data::Extended;

eval {
    my $chart = Google::Chart->new(
        type => "Line",
        size => "400x300",
        data => Google::Chart::Data::Extended->new(
            max_value=> 150,
            dataset => [ 1,50,60,20,10,130 ],
        ),
    );
};
ok( !$@) or diag($@);

eval {
    my $chart = Google::Chart->new(
        type => "Line",
        size => "400x300",
        data => Google::Chart::Data::Simple->new(
            max_value=> 150,
            dataset => [ 1,50,60,20,10,130 ],
        ),
    );
};
ok( !$@) or diag($@);
