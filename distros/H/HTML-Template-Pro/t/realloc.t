#!/usr/bin/perl -w

use Test;
BEGIN {
    $tests=30;
    plan tests => $tests;
}
use HTML::Template::Pro;
use vars qw/$test/;
my $mult=10;
my $t = HTML::Template::Pro->new( filename => 'templates-Pro/test_malloc.tmpl' , debug=>0);
for($x=25;$x<25+$tests*$mult;$x+=$mult) {
    my $txt='xxxxxxxxxx'x$x;
    $t->param('text' => $txt );
    ok($t->output eq ($txt . "\n")) ;
}
