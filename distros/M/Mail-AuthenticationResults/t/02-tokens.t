#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Token;
use Mail::AuthenticationResults::Token::Assignment;
use Mail::AuthenticationResults::Token::Comment;
use Mail::AuthenticationResults::Token::QuotedString;
use Mail::AuthenticationResults::Token::Separator;
use Mail::AuthenticationResults::Token::String;
use Mail::AuthenticationResults::Token::Space;

my $token;

# Base token
subtest 'base' => sub{
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token->new( 'test' ); }, 'Base token dies' );
};

# Assignment token
subtest 'assignment' => sub{
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::Assignment->new( '=test' ); }, 'Assignment token = lives' );
    is( $token->value(), '=', 'value correct' );
    is( $token->remainder(), 'test', 'remainder correct' );
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::Assignment->new( '/test' ); }, 'Assignment token / lives' );
    is( $token->value(), '/', 'value correct' );
    is( $token->remainder(), 'test', 'remainder correct' );
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::Assignment->new( '.test' ); }, 'Assignment token . lives' );
    is( $token->value(), '.', 'value correct' );
    is( $token->remainder(), 'test', 'remainder correct' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::Assignment->new( 'test' ); }, 'Assignment token test dies' );
};

# Comment token
subtest 'comment' => sub{
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::Comment->new( '(Comment) test' ); }, 'Comment token lives' );
    is( $token->value(), 'Comment', 'value correct' );
    is( $token->remainder(), ' test', 'remainder correct' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::Comment->new( 'Comment test' ); }, 'Comment token not comment dies' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::Comment->new( '((Comment) test' ); }, 'Comment token not closed dies' );
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::Comment->new( '(Comment)) test' ); }, 'Comment token not opened lives' ); # parses the comment it can
    is( $token->value(), 'Comment', 'value correct' );
    is( $token->remainder(), ') test', 'remainder correct' );
};

# Quoted String Token
subtest 'quoted_string' => sub{
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::QuotedString->new( '"Quoted String" test' ); }, 'Quoted String token lives' );
    is( $token->value(), 'Quoted String', 'value correct' );
    is( $token->remainder(), ' test', 'remainder correct' );
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::QuotedString->new( '"" test' ); }, 'Quoted String token empty lives' );
    is( $token->value(), '', 'value correct' );
    is( $token->remainder(), ' test', 'remainder correct' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::QuotedString->new( '"Quoted String test' ); }, 'Quoted String token not closed dies' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::QuotedString->new( 'Not a Quoted String' ); }, 'Quoted String token not quoted dies' );
};

# Separator Token
subtest 'separator' => sub{
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::Separator->new( ';test' ); }, 'Separator token ; lives' );
    is( $token->value(), ';', 'value correct' );
    is( $token->remainder(), 'test', 'remainder correct' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::Separator->new( 'test' ); }, 'Separator token test dies' );
};

# String Token
subtest 'string' => sub{
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::String->new( 'String test' ); }, 'String token lives' );
    is( $token->value(), 'String', 'value correct' );
    is( $token->remainder(), ' test', 'remainder correct' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::String->new( ' Space test' ); }, 'String token space dies' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::String->new( "\t Tab test" ); }, 'String token tab dies' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::String->new( '"Quoted test' ); }, 'String token quoted dies' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::String->new( '(Comment test' ); }, 'String token comment dies' );
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::String->new( ';Separator test' ); }, 'String token separator dies' );
};

# Space Token
subtest 'space' => sub{
    dies_ok( sub{ $token = Mail::AuthenticationResults::Token::Space->new( 'Space test' ); }, 'Space token dies' );
    lives_ok( sub{ $token = Mail::AuthenticationResults::Token::Space->new_from_value( ' ' ); }, 'Space token lives' );
    is( $token->value(), ' ', 'value correct' );
    dies_ok( sub{ $token->parse(); }, 'Parse dies' );
    dies_ok( sub{ $token->remainder(); }, 'Remainder dies' );
};

done_testing();

