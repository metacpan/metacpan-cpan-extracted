use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok("Feed::Data");
}

my $feed = Feed::Data->new();
$feed->parse( 't/data/rss20.xml' );
$feed->parse( 't/data/blog.html' );

subtest 'basic feed options' => sub {
    test_feed({
        action => 'all',
        feed => $feed,
    });
    test_feed({
        action => 'count',
        feed => $feed,
        output => 3,
    });
};

subtest 'check the values' => sub {
    test_values({
        action => 'title',
        feed => $feed,
        output => 'You can have any title you wish here',
    });
    test_values({
        action => 'description',
        feed => $feed,
        output => 'Description goes here may have to do a little validation',
    });
    test_values({
        action => 'link',
        feed => $feed,
        output => 'www.someurl.com',
    });
    test_values({
        action => 'image',
        feed => $feed,
        output => 'www.urltoimage.com/blah.jpg',
    });
};

done_testing();

sub test_values {
    my ($args) = @_;
    
    my $feed = $args->{feed};
    my $action = $args->{action};
    my $object = $feed->get(0);
    is($object->$action->raw, $args->{output}, "correct output: $action - $args->{output}");
}

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
