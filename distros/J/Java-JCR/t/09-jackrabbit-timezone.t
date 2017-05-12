# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 977;

use_ok('Java::JCR');
use_ok('Java::JCR::Jackrabbit');

my $repository = Java::JCR::Jackrabbit->new;
ok($repository);

my $session = $repository->login(
    Java::JCR::SimpleCredentials->new('username', 'password'));
ok($session);

my $root = $session->get_root_node;
ok($root);

my $node = $root->has_node('dates') 
                ? $root->get_node('dates')
                : $root->add_node('dates', 'nt:unstructured');

my $has_datetime;
my $has_class_date;

my @timezones = qw(
    Africa/Cairo
    America/Chicago
    Asia/Bangkok
    Atlantic/Bermuda
    Australia/Sydney
    Europe/Moscow
    Indian/Mayotte
    Pacific/Midway
    UTC
);

my @hours = (0, 5, 10, 15, 20, 23);

SKIP: {
    eval 'use DateTime';
    skip 'DateTime is not installed.', scalar(@timezones)*scalar(@hours) if $@;

    $has_datetime++;

    for my $tz (@timezones) {
        my $tzname = $tz;
        $tzname =~ s/\W/_/;

        for my $h (@hours) {
            my $datetime = DateTime->new(
                year => 1978,
                month => 1,
                day => 10,
                hour => $h,
                minute => 42,
                second => 57,
                time_zone => $tz,
            );

            my $property = $node->set_property(
                "datetime_${tzname}_$h" => $datetime
            );
            ok($property, "DateTime $tz $h set");
        }
    }
}

SKIP: {
    eval 'use Class::Date';
    skip 'Class::Date is not installed.', scalar(@timezones)*scalar(@hours)
        if $@;

    $has_class_date++;

    for my $tz (@timezones) {
        my $tzname = $tz;
        $tzname =~ s/\W/_/;

        for my $h (@hours) {
            my $class_date = Class::Date->new(
                [ 1978, 1, 10, $h, 42, 57 ], $tz
            );

            my $property = $node->set_property(
                "class_date_${tzname}_$h" => $class_date
            );
            ok($property, "Class::Date $tz $h set");
        }
    }
}

$session->save;

$node = $root->get_node('dates');

SKIP: {
    skip 'DateTime is not installed.', 8*scalar(@timezones)*scalar(@hours)
        if !$has_datetime;

    for my $tz (@timezones) {
        my $tzname = $tz;
        $tzname =~ s/\W/_/;

        for my $h (@hours) {
            my $property = $node->get_property("datetime_${tzname}_$h");
            my $datetime = $property->get_date('DateTime');
            ok($datetime, "DateTime $tz $h get");

            is($datetime->year, 1978, "DateTime $tz $h year");
            is($datetime->month, 1, "DateTime $tz $h month");
            is($datetime->day, 10, "DateTime $tz $h day");
            is($datetime->hour, $h, "DateTime $tz $h hour");
            is($datetime->minute, 42, "DateTime $tz $h minute");
            is($datetime->second, 57, "DateTime $tz $h second");
            is($datetime->time_zone->name, $tz, "DateTime $tz $h tz");
        }
    }
}

SKIP: {
    skip 'Class::Date is not installed.', 8*scalar(@timezones)*scalar(@hours) 
        if !$has_class_date;

    for my $tz (@timezones) {
        my $tzname = $tz;
        $tzname =~ s/\W/_/;

        for my $h (@hours) {
            my $property = $node->get_property("class_date_${tzname}_$h");
            my $class_date = $property->get_date('Class::Date');
            ok($class_date, "Class::Date $tz $h get");

            is($class_date->year, 1978, "Class::Date $tz $h year");
            is($class_date->month, 1, "Class::Date $tz $h month");
            is($class_date->day, 10, "Class::Date $tz $h day");
            is($class_date->hour, $h, "Class::Date $tz $h hour");
            is($class_date->minute, 42, "Class::Date $tz $h minute");
            is($class_date->second, 57, "Class::Date $tz $h second");
            is($class_date->tz, $tz, "Class::Date $tz $h tz");
        }
    }
}

$node->remove;
$root->save;

$session->logout;
