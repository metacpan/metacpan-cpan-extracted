#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 44;
use Mac::Safari::JavaScript qw(safari_js);
use Scalar::Util qw(blessed);
use Data::Dumper;

# force the browser to open in a sane enviroment
# where no-one has redefined anything that Safari can't
# cope with
use Mac::AppleScript qw(RunAppleScript);
RunAppleScript(<<'APPLESCRIPT');
tell application "Safari"
    make new document at end of documents
    set url of document 1 to "about:blank"
end tell
APPLESCRIPT

########################################################################
# return values
########################################################################

# simple values returned
is_deeply safari_js("return 'string'"), "string", "string";
is_deeply safari_js('return "string"'), "string", "string";
is_deeply safari_js("return 1+2+3"), 6, "number";

# truth values returned
ok safari_js("return true"), "truth, true";
ok !safari_js("return false"), "truth, false";

# return simple object
is_deeply safari_js("return { 'a': 'b'}") , { a => "b"}, "object/hash";
is_deeply safari_js("return [1,2,3]") , [1,2,3], "object/array";

# return various forms of undef
is_deeply [safari_js "1+1"], [], "doesn't return anything";
is_deeply [safari_js "return"], [undef], "bare return";
is_deeply [safari_js "return undefined"], [undef], "return undefined";
is_deeply [safari_js "return null"], [undef], "return null";

# unicode
is_deeply safari_js('return "L\\u00e9on"'), "L\x{e9}on", "unicode \\u sequence";
is safari_js("return 'L\x{e9}on'.length"), 4, "length";
is safari_js("return '\x{2603}'"), "\x{2603}", "snowman roundtrip";

# multiline, including a comment
is safari_js(<<'JAVASCRIPT'), "bobbuzz", "multiline";
// this is a multi line example
var foo = "bob";
var bar = "buzz";
return foo+bar;
JAVASCRIPT

########################################################################
# passing things in
########################################################################

is_deeply [safari_js "return foo + bar", foo => 2, bar => 3], [5], "basic in";
is_deeply [safari_js "return [number,hash,array, truth,falsehood,nully]",

  number => 6,

  hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ], hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ] } },

  array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}", { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ], hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ]}}],

  truth => JSON::XS::true,

  falsehood => JSON::XS::false,

  nully => undef,
], [[
  6,
  
  { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ], hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ] } },

  [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}", { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ], hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ]}}],

  JSON::XS::true,

  JSON::XS::false,

  undef,
]], "round trip";

########################################################################
# Bad calling
########################################################################

eval { 
  safari_js "return true;", "uneven"
};
like ($@, qr/Uneven number of parameters passed to safari_js/, "Uneven number of parameters");

eval {
  safari_js "return true;", foo => "bar", foo => "buz";
};
like ($@, qr/Duplicate parameter 'foo' passed twice to safari_js/, "Duplicate parameters");

########################################################################
# totally unexpected error 
########################################################################

eval {
  # simulate returning something totally missing anything useful and us dealing with it
  no warnings;
  local *{Mac::Safari::JavaScript::RunAppleScript} = sub { return "{}" };
  safari_js "Simulate totally unexpected error from the brower";
};
like($@, qr/Unexpected error returned when trying to communicate with Safari/, "unexpected works");

eval {
  # simulate returning something not JSON and us dealing with it
  # supress all warnings globally, because this will otherwise cause noise in the tests
  # as JSON::XS gets passed junk
  no warnings;
  local $SIG{__WARN__} = sub {};
  local *{Mac::Safari::JavaScript::RunAppleScript} = sub { return undef };
  safari_js "Simulate totally unexpected error from the brower";
};
like($@, qr/Unexpected error returned when trying to communicate with Safari/, "unexpected works");


########################################################################
# testing exceptions
########################################################################

sub error_check (&$$) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $uboat = shift;
  my $type = shift;
  my $description = shift;
  eval { $uboat->() };
  my $error = $@;
  if ($error && blessed($error) && $error->isa("Mac::Safari::JavaScript::Exception") && $error->name eq $type) {
    ok(1, $description);
    return $error;
  }
  ok(0, $description);
  diag("Error class is @{[ ref $error ]})");
  diag("Error is $error");
  return $error;
}

my $error;

$error = error_check {
  safari_js "throw 'Bang'";
} "CustomError", "string error";
is($error, "Bang","...stringifies to that error");
is($error->message,undef, "...message is however undef");

$error = error_check {
  safari_js "throw ''";
} "CustomError", "empty error";
ok($error, "...is still a true error");
is($error, "", "...stringifies to the empty string");

$error = error_check { safari_js <<'ENDOFJAVASCRIPT'; } "CustomError", "object error";
// this is a comment
throw {'foo':'bar','sourceID':'fish'};
ENDOFJAVASCRIPT
is($error->line, 2, "...has right line number")
  or diag Dumper $error;
is($error->error->{foo},"bar", "...has values");

$error = error_check { safari_js <<'ENDOFJAVASCRIPT'; } "CustomError", "object error again";
throw {'foo':'bar','sourceID':'fish'};
ENDOFJAVASCRIPT
is($error->line, 1, "...has right line number");
SKIP: {
  skip "No expressionBeginOffset set", 1 unless defined $error->expressionBeginOffset;
  is($error->expressionBeginOffset, 0, "...has right begin offset");
}
SKIP: {
  skip "No expressionEndOffset set", 1 unless defined $error->expressionEndOffset;
  is($error->expressionEndOffset, 37, "...has end offset");
}
isnt($error->sourceId,'fish', "...has new sourceID (1/2)");
ok(length($error->sourceId), "...has new sourceID (2/2)");
is($error->message, undef,"...has undefined message");

# note that different versions of Safari give different errors
# so we have regexs in the test.

$error = error_check {
  safari_js "++++";
} "SyntaxError","invalid js";
like($error,q!/\A(?:Parse error|Unexpected token ';')\z/!, "...message is also a parse error");
like($error->message,q!/\A(?:Parse error|Unexpected token ';')\z/!, "...message is also a parse error");

# this checks our eval isn't easily broken by bad syntax
$error = error_check {
  safari_js "{";
} "SyntaxError","stray }";
like($error,q!/\A(?:Parse error|Unexpected token '\)')\z/!, "...is also a parse error");

$error = error_check {
  safari_js "return new Array(-1)";
} "RangeError", "browser thrown error that isn't a syntax error";
is($error,"Array size is not a small enough positive integer.","...has right error message");
