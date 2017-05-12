# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 17;

use_ok('Java::JCR');
use_ok('Java::JCR::Jackrabbit');

my $repository = Java::JCR::Jackrabbit->new;
ok($repository);

my $session = $repository->login(
    Java::JCR::SimpleCredentials->new('username', 'password'));
ok($session);

my $root = $session->get_root_node;
ok($root);

my $node = $root->add_node('dates', 'nt:unstructured');

my $has_datetime;
my $has_class_date;

SKIP: {
    eval 'use DateTime';
    skip 'DateTime is not installed.', 1 if $@;

    $has_datetime++;

    my $datetime = DateTime->new( year => 1978, month => 1, day => 10 );

    my $property = $node->set_property('datetime', $datetime);
    ok($property);
}

SKIP: {
    eval 'use Class::Date';
    skip 'Class::Date is not installed.', 1 if $@;

    $has_class_date++;

    my $class_date = Class::Date->new([ 1978, 1, 10 ]);

    my $property = $node->set_property('class_date', $class_date);
    ok($property);
}

$session->save;

$node = $root->get_node('dates');

SKIP: {
    skip 'DateTime is not installed.', 5 if !$has_datetime;

    my $property = $node->get_property('datetime');
    my $datetime = $property->get_date('DateTime');
    ok($datetime);
    isa_ok($datetime, 'DateTime');

    is($datetime->year, 1978);
    is($datetime->month, 1);
    is($datetime->day, 10);
}

SKIP: {
    skip 'Class::Date is not installed.', 5 if !$has_class_date;

    my $property = $node->get_property('class_date');
    my $class_date = $property->get_date('Class::Date');
    ok($class_date);
    isa_ok($class_date, 'Class::Date');

    is($class_date->year, 1978);
    is($class_date->month, 1);
    is($class_date->day, 10);
}

$node->remove;
$root->save;

$session->logout;
