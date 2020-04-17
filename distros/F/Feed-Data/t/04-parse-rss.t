use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok("Feed::Data");
}

my $feed = Feed::Data->new();
$feed->parse( 't/data/rss20.xml' );

subtest 'object options' => sub {
    test_feed({
        action => 'all',
        feed => $feed,
    });
    test_feed({
        action => 'count',
        feed => $feed,
        output => 2,
    });
    test_feed({
        action => 'get',
        feed => $feed,
        input => 1,
        isa_object => 'Feed::Data::Object'
    });
    test_feed({
        action => 'delete',
        feed => $feed,
        input => 1,
    });
    test_feed({
        action => 'count',
        feed => $feed,
        output => 1
    });
};

done_testing();

sub test_feed {
    my ($args) = @_;

    my $feed = $args->{feed};
    my $action = $args->{action};
    my $input = $args->{input};
    my $output = $args->{output};
    my $isa_object = $args->{isa_object};
    my $test;

    if ($input) {
        ok($test = $feed->$action($input));
    }
    else {
        ok($test = $feed->$action);
    }

    if ($output) {
        is($test, $output, "correct output: $action");
    }
    elsif ($isa_object) {
       isa_ok($test, $isa_object, "correct output: $action");
    }
}

1;
