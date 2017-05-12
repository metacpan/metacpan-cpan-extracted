#!/home/markt/bin/perl -w
use strict;
no strict 'subs';
use lib '..';
use Java;

my $java = new Java();

my $field = $java->get_field("java.util.Locale","CHINESE");
print STDERR "FIELD: $field\n";
my $dispname = $field->getDisplayName;
print STDERR "dispname: $field\n";
my $str = $dispname->get_value;
print "Chinese Locale: $str\n";

$str = $java->create_object("java.lang.String","multie\nline\nstring\nhell");
my $val = $str->get_value;
print "VAL -$val-\n";

# test static field
my $foobie_field = $java->get_field("com.zzo.javaserver.Test","count")->get_value;
print STDERR "FIELD: $foobie_field\n";

$java->set_field("com.zzo.javaserver.Test","count", 909);
$foobie_field = $java->get_field("com.zzo.javaserver.Test","count")->get_value;
print STDERR "FIELD: $foobie_field\n";
