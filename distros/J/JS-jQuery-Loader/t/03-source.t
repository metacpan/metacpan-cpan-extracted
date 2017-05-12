use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;

use JS::jQuery::Loader::Template;
use JS::jQuery::Loader::Source::URI;

my $uri = "http://jqueryjs.googlecode.com/files/\%j";
my $template = JS::jQuery::Loader::Template->new;
my $source = JS::jQuery::Loader::Source::URI->new(template => $template, uri => $uri);

is($source->uri, "http://jqueryjs.googlecode.com/files/jquery.js");

$template->version("1.2.3");
$source->recalculate;
is($source->uri, "http://jqueryjs.googlecode.com/files/jquery-1.2.3.js");

$template->filter("min");
$source->recalculate;
is($source->uri, "http://jqueryjs.googlecode.com/files/jquery-1.2.3.min.js");

$template->version("");
$source->recalculate;
is($source->uri, "http://jqueryjs.googlecode.com/files/jquery.min.js");
