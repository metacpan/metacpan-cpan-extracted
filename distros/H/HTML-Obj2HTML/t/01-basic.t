use strict;
use HTML::Obj2HTML;
use Test::More;

my $str = HTML::Obj2HTML::gen(
  [
    doctype => "html",
    html => [
      head => [
        title => "Test web page"
      ],
      body => [
        p => "Hello World!"
      ]
    ]
  ]
);

is($str, "<!DOCTYPE html><html><head><title>Test web page</title></head><body><p>Hello World!</p></body></html>", "Basic web page rendering");

done_testing;
