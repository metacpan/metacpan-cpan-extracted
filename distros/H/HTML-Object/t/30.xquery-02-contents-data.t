#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib qw( ./lib );
    use vars qw( $DEBUG );
    use Test::More;
    use Module::Generic::File qw( file );
    use Scalar::Util ();
};

BEGIN
{
    use_ok( 'HTML::Object::DOM', qw( global_dom 1 xquery 1 ) ) || BAIL_OUT( "Cannot load HTML::Object::DOM" );
    use_ok( 'HTML::Object::XQuery' ) || BAIL_OUT( "Cannot load HTML::Object::XQuery" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

$HTML::Object::FATAL_ERROR = 0;

# Class manipulation, contents filtering/wrapping, data storage

subtest 'addClass' => sub
{
    my $div = $( '<div />', { id => "div_1", class => "hello" });
    ok( $div->addClass( 'bye' ), 'addClass' );
    diag( $div->as_string ) if( $DEBUG );
    ok( $div->hasClass( 'bye' ), 'div class added' );
};

subtest 'contents' => sub
{
    my $page = <<EOT;
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>add demo</title>
    </head>
    <body>
        <div class="container">
            Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed
            do eiusmod tempor incididunt ut labore et dolore magna aliqua.
            <br><br>
            Ut enim ad minim veniam, quis nostrud exercitation ullamco
            laboris nisi ut aliquip ex ea commodo consequat.
            <br><br>
            Duis aute irure dolor in reprehenderit in voluptate velit
            esse cillum dolore eu fugiat nulla pariatur.
        </div>
    </body>
</html>
EOT
    HTML::Object::DOM->set_dom( $page );
    my $dom = HTML::Object::DOM->get_dom;
    use HTML::Object::DOM::Node;
    my $elem = $('.container');
    # $elem->debug(5);
    $elem
        ->contents()
        ->filter(sub
        {
            my( $i, $e ) = @_;
            # diag( "Called for index $i for element '", ( $e // 'undef' ), "' and with \$_ = '", ( $_ // 'undef' ), "'" );
            return $_->nodeType == TEXT_NODE;
            # or
            # return $_->nodeType == 3;
        })
        ->wrap( "<p></p>" )
        # Revert back to $('.container') children
        ->end()
        ->filter( "br" )
        ->remove();
    my $expect = <<EOT;
        <div class="container"><p>
            Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed
            do eiusmod tempor incididunt ut labore et dolore magna aliqua.
            </p><p>
            Ut enim ad minim veniam, quis nostrud exercitation ullamco
            laboris nisi ut aliquip ex ea commodo consequat.
            </p><p>
            Duis aute irure dolor in reprehenderit in voluptate velit
            esse cillum dolore eu fugiat nulla pariatur.
        </p></div>
EOT
    chomp( $expect );
    # $expect =~ s/\n[[:blank:]\h\v]*//gs;
    $expect =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//gs;
    is( $('.container')->as_string( all => 1 ), $expect, 'contents with filter and wrap' );
};

subtest 'data' => sub
{
    my $blank = <<EOT;
<!DOCTYPE html>
<html lang="en-GB">
    <head>
        <meta charset="utf-8" />
        <title></title>
    </head>
    <body>
    </body>
</html>
EOT
    HTML::Object::DOM->set_dom( $blank );
    my $dom = HTML::Object::DOM->get_dom;
    my $body = $('body');
    $body->data( 'foo', 52 );
    is( $body->data( 'foo' ), 52, 'data set number' );
    $body->data( 'bar', { isManual => 1 } );
    is( Scalar::Util::reftype( $body->data( 'bar' ) // '' ), 'HASH', 'data set hash' );
    if( Scalar::Util::reftype( $body->data( 'bar' ) // '' ) eq 'HASH' )
    {
        ok( $body->data( "bar" )->{isManual}, 'data value is true' );
    }
    else
    {
        fail( 'data value is true' );
    }
    $body->data( { baz => [ 1, 2, 3 ] } );
    my $rv = $body->data( 'baz' );
    is( ref( $rv ), 'ARRAY', 'data set property value is an array' );
    $rv = $body->data(); # { foo => 52, bar => { isManual => true }, baz => [ 1, 2, 3 ] }
    is( Scalar::Util::reftype( $rv ), 'HASH', 'data returning all' );
    # diag( "Value returned from \$('body')->data() is: $rv" );
    if( Scalar::Util::reftype( $rv ) eq 'HASH' )
    {
        is( $rv->foo, 52, 'data value set check' );
        # diag( "\$rv->bar returns: '", ( $rv->bar // 'undef' ), "'" );
        ok( ( Scalar::Util::reftype( $rv->bar ) eq 'HASH' && $rv->bar->isManual ), 'data value set check: bar->isManual' );
        # diag( "\$rv->baz returns: '", ( $rv->baz // 'undef' ), "'" );
        ok( ( Scalar::Util::reftype( $rv->baz ) eq 'ARRAY' && $rv->baz->[1] == 2 ), 'data value set check: baz->[]' );
    }
    else
    {
        fail( 'data value set check' );
    }
    my $div = $('<div />');
    $div->data( 'test', { first => 16, last => 'pizza!' } );
    $rv = $div->data( 'test' );
    if( Scalar::Util::reftype( $rv ) eq 'HASH' )
    {
        is( $rv->{first}, 16, 'data get returns a dynamic hash' );
        is( $rv->{last}, 'pizza!', 'data get returns a dynamic hash' );
    }
    else
    {
        fail( 'data get returns a dynamic hash' );
    }
};


done_testing();

__END__
