
use Test::More tests => 13;
use JSON::Streaming::Writer::TestUtil;

test_jsonw("Empty array", "[]", sub {
    my $jsonw = shift;
    $jsonw->start_array();
    $jsonw->end_array();
});

test_jsonw("Empty object", "{}", sub {
    my $jsonw = shift;
    $jsonw->start_object();
    $jsonw->end_object();
});

test_jsonw("Array containing string", '["5"]', sub {
    my $jsonw = shift;
    $jsonw->start_array();
    $jsonw->add_string(5);
    $jsonw->end_array();
});

test_jsonw("Object containing integer", '{"key":5}', sub {
    my $jsonw = shift;
    $jsonw->start_object();
    $jsonw->start_property("key");
    $jsonw->add_number("5");
    $jsonw->end_property();
    $jsonw->end_object();
});

test_jsonw("Array containing two nulls", '[null,null]', sub {
    my $jsonw = shift;
    $jsonw->start_array();
    $jsonw->add_null();
    $jsonw->add_null();
    $jsonw->end_array();
});

test_jsonw("Array containing three nulls", '[null,null,null]', sub {
    my $jsonw = shift;
    $jsonw->start_array();
    $jsonw->add_null();
    $jsonw->add_null();
    $jsonw->add_null();
    $jsonw->end_array();
});

test_jsonw("Array containing a weird number", '[1e-20]', sub {
    my $jsonw = shift;
    $jsonw->start_array();
    $jsonw->add_number("1e-20");
    $jsonw->end_array();
});

test_jsonw("Array containing both booleans", '[true,false]', sub {
    my $jsonw = shift;
    $jsonw->start_array();
    $jsonw->add_boolean("some true value");
    $jsonw->add_boolean("");
    $jsonw->end_array();
});

test_jsonw_croak("Generating multiple top-level values causes croak", sub {
    my $jsonw = shift;
    $jsonw->start_object();
    $jsonw->end_object();
    $jsonw->start_object();
    $jsonw->end_object();
});

test_jsonw_croak("Generating strings at the top-level causes croak", sub {
    my $jsonw = shift;
    $jsonw->add_string("blah");
});

test_jsonw_croak("Generating properties at the top-level causes croak", sub {
    my $jsonw = shift;
    $jsonw->start_property("blah");
});

test_jsonw_croak("Generating values directly inside objects causes croak", sub {
    my $jsonw = shift;
    $jsonw->intentionally_ending_early();
    $jsonw->start_object();
    $jsonw->add_string("blah");
    $jsonw->end_object();
});

test_jsonw_croak("Generating properties directly inside arrays causes croak", sub {
    my $jsonw = shift;
    $jsonw->intentionally_ending_early();
    $jsonw->start_array();
    $jsonw->start_property("blah");
});

