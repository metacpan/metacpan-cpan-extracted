use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 6 }

# load your module...
use HTML::Tag;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing HTML::Tag::DATETIME\n";

my $obj = HTML::Tag->new(element=>'DATETIME', name=>'test');

ok(defined $obj);

print $obj->html;

ok($obj->html,qr/<script language=\"javascript\">\n\tvar html_tag_datetime_js_path = '';/ 
					&& qr/<input type=\"text\" htmltag=\"datetime\" name=\"test\" value=\"\" \/>/);
$obj = HTML::Tag->new(element=>'DATETIME', name=>'value_test', value=>"1969-07-21");
ok($obj->html,qr/<input type=\"text\" htmltag=\"datetime\" name=\"value_test\" value=\"1969-07-21\" \/>/);

$obj = HTML::Tag->new(element=>'DATETIME', name=>'another_test', value=>"");
ok($obj->html,qr/name=\"another_test\" value=\"\" \/>/);

$obj = HTML::Tag->new(element=>'DATETIME', name=>'ya_test', value=>"77868");
ok($obj->html,qr/name=\"ya_test\" value=\"77868\" \/>/);

$obj = HTML::Tag->new(element=>'DATETIME', name=>'ya_test', value=>"now");
my ($min,$hour,$day,$month,$year) = (localtime())[1..5];
$year += 1900;
$month++;
$month  = "0$month" if length($month) == 1;
$day    = "0$day" if length($day) == 1;
$min    = "0$min" if length($min) == 1;
$hour    = "0$hour" if length($hour) == 1;
my $value  = "$year-$month-$day $hour:$min:00";
ok($obj->html,qr/name=\"ya_test\" value=\"$value\" \/>/);

