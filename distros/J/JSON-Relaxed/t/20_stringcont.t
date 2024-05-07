#! perl

use v5.26;

use Test::More tests => 7;
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

$p = JSON::Relaxed::Parser->new( strict => 1 );
# By using 'parse', we do not croak.
my $res = $p->parse(<<'EOD');
is( $p->parse(<<'EOD'), "foobar" );
"foo"\
"bar"
EOD
diag("$JSON::Relaxed::err_msg") if $JSON::Relaxed::err_msg;
ok( !defined($res), "no string concat (strict)" );
like($p->err_msg, qr/more than one structure/, "no string concat (strict)" );
