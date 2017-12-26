#!perl
use 5.006;
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
dies_ok( sub{ $Comment->set_value( 'a)b' ) }, 'set_value("a)b") dies' );
dies_ok( sub{ $Comment->set_value( 'a((b)' ) }, 'set_value("a((b)") dies' );
dies_ok( sub{ $Comment->set_value( '(b))a' ) }, 'set_value("(b))a") dies' );
dies_ok( sub{ $Comment->set_value( ')(' ) }, 'set_value(")(") dies' );

my $SetValue;
lives_ok( sub{ $SetValue = $Comment->set_value( 'foo' ) }, 'set_value("foo") lives' );
is( ref $SetValue, 'Mail::AuthenticationResults::Header::Comment', 'Returns Comment Object' );
is( $SetValue, $Comment, 'Returns This Object' );

is( $Comment->value(), 'foo', 'value() correct value returned' );
is( $Comment->as_string(), '(foo)', 'as_string() correct string returned' );

done_testing();

