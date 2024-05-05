#! perl

use v5.26;

use Test::More tests => 5;
use JSON::Relaxed;

my $p = JSON::Relaxed::Parser->new;

is( $p->parse(<<'EOD'), "foobar" );
"foo"\
"bar"
EOD
diag("$JSON::Relaxed::err_msg") if $JSON::Relaxed::err_msg;

is( $p->parse(<<'EOD'), "foobar" );
"foo" \
"bar"
EOD
diag("$JSON::Relaxed::err_msg") if $JSON::Relaxed::err_msg;

is( $p->parse(<<'EOD'), "foobar" );
"foo"\
 "bar"
EOD
diag("$JSON::Relaxed::err_msg") if $JSON::Relaxed::err_msg;

is( $p->parse(<<'EOD'), "foobarbleach" );
"foo" \
 'bar' \
"bleach"
EOD
diag("$JSON::Relaxed::err_msg") if $JSON::Relaxed::err_msg;

is( $p->parse( "\"foo\" \\\n \"bar\""), "foobar" );
diag("$JSON::Relaxed::err_msg") if $JSON::Relaxed::err_msg;

