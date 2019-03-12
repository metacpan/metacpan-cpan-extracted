#!perl
use strict;
use warnings;
use utf8;
use Test2::V0;
use JSON 'from_json';
use JSON::Feed;

my $feed = JSON::Feed->new(
    title => "Test. $$"
);
$feed->add_item(
    id => "/foo",
    title => "Foo",
);
$feed->add_item(
    id => "/bar",
    title => "Bar",
);

my $o = from_json( $feed->to_string );
ok defined($o->{version});
is $o->{title}, "Test. $$";
is $o->{items}, [
    { id => "/foo", title => "Foo" },
    { id => "/bar", title => "Bar" },
];
done_testing;
