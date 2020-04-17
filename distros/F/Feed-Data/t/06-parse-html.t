use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok("Feed::Data");
}

my $feed = Feed::Data->new();
$feed->parse( 't/data/blog.html' );

subtest 'basic feed options' => sub {
    test_feed({
        action => 'all',
        feed => $feed,
    });
    test_feed({
        action => 'count',
        feed => $feed,
        output => 1,
    });
    test_feed({
        action => 'get',
        feed => $feed,
        input => 0,
        isa_object => 'Feed::Data::Object'
    });
    test_feed({
        action => 'delete',
        feed => $feed,
        input => 0,
    });
    test_feed({
        action => 'count',
        feed => $feed,
        output => 0
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

    if (defined $input) {
        ok($test = $feed->$action($input));
    }
    else {
	$test = $feed->$action;
	ok(defined $test);
    }

    if (defined $output) {
        is($test, $output, "correct output: $action");
    }
    elsif ($isa_object) {
       isa_ok($test, $isa_object, "correct output: $action");
    }
}

1;
