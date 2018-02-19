#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Header::Comment;

my $Comment;
lives_ok( sub{ $Comment = Mail::AuthenticationResults::Header::Comment->new() }, 'new()' );
is( ref $Comment, 'Mail::AuthenticationResults::Header::Comment', 'Returns Comment Object' );

dies_ok( sub{ $Comment->set_key( 'foo' ) }, 'set_key() dies' );
dies_ok( sub{ $Comment->key() }, 'key() dies' );

dies_ok( sub{ $Comment->add_child( $Comment ) }, 'add_child() dies' );
dies_ok( sub{ $Comment->children() }, 'children() dies' );

dies_ok( sub{ $Comment->set_value( 'a(b' ) }, 'set_value("a(b") dies' );
lives_ok( sub{ $Comment->safe_set_value( 'a(b' ) }, 'safe_set_value("a(b") lives' );
is( $Comment->value(), 'a b', 'value() correct value returned' );

dies_ok( sub{ $Comment->set_value( 'a)b' ) }, 'set_value("a)b") dies' );
lives_ok( sub{ $Comment->safe_set_value( 'a)b' ) }, 'safe_set_value("a)b") lives' );
is( $Comment->value(), 'a b', 'value() correct value returned' );

dies_ok( sub{ $Comment->set_value( 'a((b)' ) }, 'set_value("a((b)") dies' );
lives_ok( sub{ $Comment->safe_set_value( 'a((b)' ) }, 'safe_set_value("a((b)") lives' );
is( $Comment->value(), 'a  b', 'value() correct value returned' );

dies_ok( sub{ $Comment->set_value( '(b))a' ) }, 'set_value("(b))a") dies' );
lives_ok( sub{ $Comment->safe_set_value( '(b))a' ) }, 'safe_set_value("(b))a") lives' );
is( $Comment->value(), 'b  a', 'value() correct value returned' );

dies_ok( sub{ $Comment->set_value( ')(' ) }, 'set_value(")(") dies' );
lives_ok( sub{ $Comment->safe_set_value( ')(' ) }, 'safe_set_value(")(") lives' );
is( $Comment->value(), '', 'value() correct value returned' );

my $SetValue;
lives_ok( sub{ $SetValue = $Comment->set_value( 'foo' ) }, 'set_value("foo") lives' );
is( ref $SetValue, 'Mail::AuthenticationResults::Header::Comment', 'Returns Comment Object' );
is( $SetValue, $Comment, 'Returns This Object' );

is( $Comment->value(), 'foo', 'value() correct value returned' );
is( $Comment->as_string(), '(foo)', 'as_string() correct string returned' );

lives_ok( sub{ $SetValue = $Comment->set_value( 'foo(bar)' ) }, 'set_value("foo(bar)") lives' );
is( $Comment->value(), 'foo(bar)', 'value() correct value returned' );
is( $Comment->as_string(), '(foo(bar))', 'as_string() correct string returned' );

lives_ok( sub{ $SetValue = $Comment->safe_set_value( 'foo' ) }, 'safe_set_value("foo") lives' );
is( $Comment->value(), 'foo', 'value() correct value returned' );
is( $Comment->as_string(), '(foo)', 'as_string() correct string returned' );

lives_ok( sub{ $SetValue = $Comment->safe_set_value( 'foo(bar)' ) }, 'safe_set_value("foo(bar)") lives' );
is( $Comment->value(), 'foo(bar)', 'value() correct value returned' );
is( $Comment->as_string(), '(foo(bar))', 'as_string() correct string returned' );

done_testing();

