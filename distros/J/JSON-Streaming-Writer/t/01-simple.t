
use Test::More tests => 21;
use JSON::Streaming::Writer::TestUtil;

# These tests are for the add_value and add_property
# methods which take Perl values and generate sensible
# JSON representations.

test_jsonw("Empty array", "[]", sub {
    my $jsonw = shift;
    $jsonw->add_value([]);
});

test_jsonw("Empty object", "{}", sub {
    my $jsonw = shift;
    $jsonw->add_value({});
});

test_jsonw("Array containing string", '["ok"]', sub {
    my $jsonw = shift;
    $jsonw->add_value(["ok"]);
});

test_jsonw("Object containing string", '{"key":"value"}', sub {
    my $jsonw = shift;
    $jsonw->add_value({"key" => "value"});
});

test_jsonw("Array containing two nulls", '[null,null]', sub {
    my $jsonw = shift;
    $jsonw->add_value([undef,undef]);
});

test_jsonw("Array containing three nulls", '[null,null,null]', sub {
    my $jsonw = shift;
    $jsonw->add_value([undef,undef,undef]);
});

test_jsonw("Array containing an integer", '[1]', sub {
    my $jsonw = shift;
    $jsonw->add_value([1]);
});

test_jsonw("Array containing an number", '[1.5]', sub {
    my $jsonw = shift;
    $jsonw->add_value([1.5]);
});

test_jsonw("Array containing a weird number", '[1e-20]', sub {
    my $jsonw = shift;
    $jsonw->add_value([1e-20]);
});

test_jsonw("Array containing both booleans", '[true,false]', sub {
    my $jsonw = shift;
    $jsonw->add_value([\1, \0]);
});

test_jsonw_croak("Top-level string causes croak", sub {
    my $jsonw = shift;
    $jsonw->add_value("Hello");
});

test_jsonw_croak("Top-level integer causes croak", sub {
    my $jsonw = shift;
    $jsonw->add_value(1);
});

test_jsonw_croak("Top-level number causes croak", sub {
    my $jsonw = shift;
    $jsonw->add_value(1.5);
});

test_jsonw_croak("Top-level null causes croak", sub {
    my $jsonw = shift;
    $jsonw->add_value(undef);
});

test_jsonw_croak("Top-level boolean causes croak", sub {
    my $jsonw = shift;
    $jsonw->add_value(\1);
});

test_jsonw("add_property inside an object", '{"hello":"world"}', sub {
    my $jsonw = shift;
    $jsonw->start_object();
    $jsonw->add_property("hello" => "world");
    $jsonw->end_object();
});

test_jsonw("add_value inside an array", '["foo"]', sub {
    my $jsonw = shift;
    $jsonw->start_array();
    $jsonw->add_value("foo");
    $jsonw->end_array();
});

test_jsonw_croak("add_property inside an array fails", sub {
    my $jsonw = shift;
    $jsonw->intentionally_ending_early();
    $jsonw->start_array();
    $jsonw->add_property("hello" => "world");
    $jsonw->end_array();
});

test_jsonw_croak("add_value inside an object fails", sub {
    my $jsonw = shift;
    $jsonw->intentionally_ending_early();
    $jsonw->start_object();
    $jsonw->add_value("foo");
    $jsonw->end_object();
});

test_jsonw_croak("add_property at the top level fails", sub {
    my $jsonw = shift;
    $jsonw->intentionally_ending_early();
    $jsonw->add_property("hello" => "world");
});

test_jsonw("both add_property and explicity start_property inside an object", '{"simple":true,"normal":false}', sub {
    my $jsonw = shift;
    $jsonw->start_object();
    $jsonw->add_property("simple" => \1);
    $jsonw->start_property("normal");
    $jsonw->add_value(\0);
    $jsonw->end_property();
    $jsonw->end_object();
});

