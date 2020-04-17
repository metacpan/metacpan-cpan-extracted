use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok("Feed::Data");
    use_ok("Feed::Data::Object");
}

my $feed = Feed::Data->new();
$feed->parse( 't/data/rss20.xml' );

subtest 'object attributes set' => sub {
    test_attributes({
        action => 'title',
        feed => $feed,
        isa => 'Feed::Data::Object::Title'
    });
    test_attributes({
        action => 'link',
        feed => $feed,
        isa => 'Feed::Data::Object::Link'
    });
    test_attributes({
        action => 'description',
        feed => $feed,
        isa => 'Feed::Data::Object::Description'
    });
    test_attributes({
        action => 'image',
        feed => $feed,
        isa => 'Feed::Data::Object::Image'
    });
    test_attributes({
        action => 'date',
        feed => $feed,
        isa => 'Feed::Data::Object::Date'
    });
};

done_testing();

sub test_attributes {
    my ( $args ) = @_;

    $feed = $args->{feed};
    my $first = $feed->get(0);
    my $action = $args->{action};

    isa_ok($first->$action, $args->{isa}, "Attribute Set: $args->{isa}");
}

sub test_options {
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
