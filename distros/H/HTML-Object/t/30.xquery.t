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
    # use_ok( 'HTML::Object::Element' ) || BAIL_OUT( "Cannot load HTML::Object::Element" );
    use_ok( 'HTML::Object::XQuery' ) || BAIL_OUT( "Cannot load HTML::Object::XQuery" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

$HTML::Object::FATAL_ERROR = 0;

subtest 'core' => sub
{
    # my $parser = HTML::Object::DOM->new( debug => $DEBUG );
    my $parser = HTML::Object::DOM->new;
    isa_ok( $parser, 'HTML::Object::DOM' ) || BAIL_OUT( "Unable to instantiate a HTML::Object::DOM object." );
    my $test_file = './t/test.html';
    my $doc = $parser->parse( $test_file );
    isa_ok( $doc, 'HTML::Object::DOM::Document' );
    if( !defined( $doc ) )
    {
        die( "Unable to get a document object from parsing file $test_file: ", $parser->error, "\n" );
    }
    my $div = $( '<div />', { id => "div_1", class => "hello" });
    diag( "Div created is '$div'" ) if( $DEBUG );
    isa_ok( $div, 'HTML::Object::DOM::Element', 'xq creates div element' );
    diag( "\$div has ", $div->children->length, " children." ) if( $DEBUG );
    if( $DEBUG )
    {
        $div->children->for(sub
        {
            my( $i, $el ) = @_;
            diag( "Child No $i is: '", $el->as_string, "'" );
        });
    }
    diag( $div->as_string ) if( $DEBUG );
    # $div->debug($DEBUG) if( $DEBUG );
    is( $div->tag, 'div', 'tag name' );
    ok( $div->hasClass( 'hello' ), 'has class hello' );
    is( $div->id, 'div_1', 'div id' );
    my $p_fail = $('p', 'not an element object');
    ok( !defined( $p_fail ), 'selector with bad context' );
    note( "Error was: ", HTML::Object::DOM->error ) if( $DEBUG );
};

# $self->add( $selector );
# $self->add( $elements );
# $self->add( $html );
# $self->add( $selector, $context );
# <https://api.jquery.com/add/#add-selector>
subtest 'add' => sub
{
    my $test = <<EOT;
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>add demo</title>
    </head>
    <body>
        <div></div>
        <div></div>
        <div></div>
        <div></div>
        <div></div>
        <div></div>

        <p>Added this... (notice no border)</p>
    </body>
</html>
EOT
    HTML::Object::DOM->set_dom( $test );
    my $dom = HTML::Object::DOM->get_dom;
    $dom->debug( $DEBUG );
    my $elem = $( "div" )->css( "border", "2px solid red" )->add( "p" )->css( "background", "yellow" );

    my $expect = <<EOT;
        <div style="border: 2px solid red; background: yellow;"></div>
        <div style="border: 2px solid red; background: yellow;"></div>
        <div style="border: 2px solid red; background: yellow;"></div>
        <div style="border: 2px solid red; background: yellow;"></div>
        <div style="border: 2px solid red; background: yellow;"></div>
        <div style="border: 2px solid red; background: yellow;"></div>
 
        <p style="background: yellow;">Added this... (notice no border)</p>
EOT
    chomp( $expect );
    $expect =~ s/\n[[:blank:]]*//g;
    $expect =~ s/^[[:blank:]]+|[[:blank:]]+$//g;
    is( $elem->as_string( all => 1 ), $expect, 'add elements then change css' );
};

subtest 'before after' => sub
{
    my $div = $( '<div />', { id => "div_1", class => "hello" });
    ok( $div->after( '<p>Test</p>' ), '<p>Test</p> added after div' );
    # Provide some context, just like jQuery does
    my $p = $('p', $div);
    isa_ok( $p, 'HTML::Object::DOM::Element', '<p>Test</p> found' );

    my $test_before_after = <<EOT;
<div class="container">
  <h2>Greetings</h2>
  <div class="inner">Hello</div>
  <div class="inner">Goodbye</div>
</div>
EOT
    # Transform the block of text into object à la jQuery
    # local $HTML::Object::XQuery::DEBUG = 4;
    my $t_after = $( $test_before_after );
    diag( "Test before after has ", $t_after->length, " children." ) if( $DEBUG );
    $t_after->debug( $DEBUG );
    $( ".inner", $t_after )->after( "<p>Test</p>" ) || do
    {
        diag( "Error: ", $t_after->error );
    };
    diag( $t_after->as_string() ) if( $DEBUG );

    my $test_after_expected = <<EOT;
<div class="container">
  <h2>Greetings</h2>
  <div class="inner">Hello</div><p>Test</p>
  <div class="inner">Goodbye</div><p>Test</p>
</div>
EOT
    chomp( $test_after_expected );
    is( $t_after->as_string, $test_after_expected );
    my $t_before = $( $test_before_after );
    # $t_before->debug( $DEBUG );
    $( ".inner", $t_before )->before( "<p>Test</p>" );
    diag( $t_before->as_string() ) if( $DEBUG );
    my $test_before_expected = <<EOT;
<div class="container">
  <h2>Greetings</h2>
  <p>Test</p><div class="inner">Hello</div>
  <p>Test</p><div class="inner">Goodbye</div>
</div>
EOT
    chomp( $test_before_expected );
    is( $t_before->as_string, $test_before_expected );
};

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

subtest 'load' => sub
{
    my $div = $('<div />', { id => 'hello' } );
    my $f = file( "./t/test_load.html" );
    my $parser = HTML::Object::DOM->new;
    SKIP:
    {
        if( !$parser->_load_class( 'HTTP::Promise', { version => 'v0.5.0' } ) ||
            !$parser->_load_class( 'URI', { version => '1.74' } ) )
        {
            skip( "HTTP::Promise and URI are required for those tests.", 6 );
        }
        $div->load( $f->uri ) || do
        {
            diag( "Error loading $f into div: ", $div->error ) if( $DEBUG );
        };
        diag( $div->as_string ) if( $DEBUG );
        is( $div->children->length, 1, 'div # of children' );
        
        my $f2 = "./t/test_load2.html";

        my $page = $parser->parse_file( $f2 ) || do
        {
            skip( "Unable to parse $f2: " . $parser->error, 5 );
        };
        HTML::Object::DOM->set_dom( $page );
        my $frag_source = file("./t/test_load_fragment.html");
        my $frag_uri = $frag_source->uri;
        my $status;
        my $elem = $( "#new-projects" )->load( "$frag_uri #projects li", sub
        {
            my( $content, $textStatus, $respObject ) = @_;
            diag( "Called back with ", CORE::length( $content ), " bytes of content, response status set to '$textStatus' and response object '$respObject'" ) if( $DEBUG );
            $status = $textStatus;
        });
        isa_ok( $elem, 'HTML::Object::DOM::Element' );
        is( $status, 'success', 'response status' );
        if( !defined( $elem ) )
        {
            diag( "Error loading fragment '#projects li' from ./t/test_load_fragment.html: ", HTML::Object::DOM->error ) if( $DEBUG );
            skip( "failed loading fragment", 1 );
        }
        is( $elem->children->first->children->length, 5, "fragment loaded" );
        diag( $elem->as_string( all => 1 ) ) if( $DEBUG );

        # Test failed response status
        # Reset the element content
        $elem->children->first->empty();
        my $rsrc = file( "./t/not-found.html" );
        $status = '';
        diag( "Attempting to load ", $rsrc->uri, ", which should fail." ) if( $DEBUG );
        my $rv = $elem->load( $rsrc->uri, sub
        {
            my( $content, $textStatus, $respObject ) = @_;
            diag( "Called back with ", CORE::length( $content ), " bytes of content, rsponse status set to '$textStatus' and response object '$respObject'" ) if( $DEBUG );
            $status = $textStatus;
        });
        diag( "load() returned '$rv'" ) if( $DEBUG );
        is( $status, 'error', 'failed status' );
        is( $rv, undef, 'load returned undefined' );
    };
};

subtest 'wrap' => sub
{
    my $blank = <<EOT;
<!DOCTYPE html>
<html lang="en-GB">
    <head>
        <meta charset="utf-8" />
        <title></title>
    </head>
    <body>
        <p>Hello</p>
        <p>cruel</p>
        <p>World</p>
    </body>
</html>
EOT
    my $parser = HTML::Object::DOM->new;
    SKIP:
    {
        my $doc = $parser->parse_data( $blank ) || do
        {
            skip( "Unable to parse blank html: " . $parser->error, 1 );
        };
        HTML::Object::DOM->set_dom( $doc );
        $('p')->wrap( '<div></div>' );
        my $body = $doc->body;
        my $html = $body->html;
        $html =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//gs;
        like( $html, qr{<div><p>Hello</p></div>[[:blank:]\h\v]+<div><p>cruel</p></div>[[:blank:]\h\v]+<div><p>World</p></div>}, 'wrap' );
    };
    $blank = <<EOT;
<!DOCTYPE html>
<html lang="en-GB">
    <head>
        <meta charset="utf-8" />
        <title></title>
    </head>
    <body>
        <div class="container">
            <div class="inner">Hello</div>
            <div class="inner">Goodbye</div>
        </div>
    </body>
</html>
EOT
    $parser = HTML::Object::DOM->new;
    SKIP:
    {
        my $doc = $parser->parse_data( $blank ) || do
        {
            skip( "Unable to parse blank html: " . $parser->error, 1 );
        };
        HTML::Object::DOM->set_dom( $doc );
        $('.inner')->wrap( '<div class="new"></div>' );
        my $container = $('.container');
        my $html = $container->html;
        $html =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//gs;
        like( $html, qr{<div class="new"><div class="inner">Hello</div></div>[[:blank:]\h\v]+<div class="new"><div class="inner">Goodbye</div></div>}, 'wrap' );
    };
    $parser = HTML::Object::DOM->new;
    SKIP:
    {
        my $doc = $parser->parse_data( $blank ) || do
        {
            skip( "Unable to parse blank html: " . $parser->error, 1 );
        };
        HTML::Object::DOM->set_dom( $doc );
        $('.inner')->wrap(sub
        {
            return( '<div class="' . $_->text . '"></div>' );
        });
        my $container = $('.container');
        my $html = $container->html;
        $html =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//gs;
        like( $html, qr{<div class="Hello"><div class="inner">Hello</div></div>[[:blank:]\h\v]+<div class="Goodbye"><div class="inner">Goodbye</div></div>}, 'wrap with callback' );
    };
    $blank = <<EOT;
<!DOCTYPE html>
<html lang="en-GB">
    <head>
        <meta charset="utf-8" />
        <title></title>
    </head>
    <body>
        <span>Span Text</span>
        <strong>What about me?</strong>
        <span>Another One</span>
    </body>
</html>
EOT
    $parser = HTML::Object::DOM->new;
    SKIP:
    {
        my $doc = $parser->parse_data( $blank ) || do
        {
            skip( "Unable to parse blank html: " . $parser->error, 1 );
        };
        HTML::Object::DOM->set_dom( $doc );
        $('span')->wrap( '<div><div><p><em><b></b></em></p></div></div>' );
        my $body = $doc->body;
        my $html = $body->html;
        $html =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//gs;
        like( $html, qr{^<div><div><p><em><b><span>Span Text</span></b></em></p></div></div>[[:blank:]\h\v]+<strong>What about me\?</strong>[[:blank:]\h\v]*<div><div><p><em><b><span>Another One</span></b></em></p></div></div>$}, 'wrap nested structure' );
    };
};

# NOTE: $. or xQuery class functions
subtest 'contains' => sub
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
    my $parser = HTML::Object::DOM->new;
    SKIP:
    {
        my $doc = $parser->parse_data( $blank ) || do
        {
            skip( "Unable to parse blank html: " . $parser->error, 3 );
        };
        HTML::Object::DOM->set_dom( $doc );
        # $.contains( document.documentElement, document.body ); # true
        # $.contains( document.body, document.documentElement ); # false
        ok( xQuery->contains( $doc->documentElement, $doc->body ), 'body is contained by html element' );
        ok( !xQuery->contains( $doc->body, $doc->documentElement ), 'html element is not contained by body' );
        my $body = $doc->body;
        ok( !$body->contains( $doc->documentElement ), 'html element is not contained by body (using 1 element object)' );
    };
};

subtest 'extend' => sub
{
    my $hash1 =
    {
        apple => 0,
        banana => { weight => 52, price => 100 },
        cherry => 97,
    };
    
    my $hash2 = 
    {
        banana => { price => 200 },
        durian => 100,
    };

    SKIP:
    {
        my $ref = $.extend( $hash1, $hash2 );
        is( ref( $ref ), 'HASH', 'value returned by $.extend is an hash reference' );
        if( ref( $ref ) ne 'HASH' )
        {
            skip( 'Value returned by $.extend is not an hash reference.', 3 );
        }
        ok( ( exists( $ref->{banana} ) && ref( $ref->{banana} ) && ref( $ref->{banana} ) eq 'HASH' && !exists( $ref->{banana}->{weight} ) ), 'simple merge with $.extend' );
        # Pass first argument as boolean to indicate deep recursion
        my $ref2 = $.extend( 1, $hash1, $hash2 );
        if( ref( $ref2 ) ne 'HASH' )
        {
            skip( 'Value returned by $.extend is not an hash reference.', 3 );
        }
        ok(( exists( $ref2->{banana} ) && ref( $ref2->{banana} ) && ref( $ref2->{banana} ) eq 'HASH' && exists( $ref2->{banana}->{weight} ) && $ref2->{banana}->{weight} == 52 ), 'deep merge with $.extend' );
    };
};

subtest 'grep' => sub
{
    my $arr = [ 1, 9, 3, 8, 6, 1, 5, 9, 4, 7, 3, 8, 6, 9, 1 ];
    local $" = ', ';
    $arr = xQuery->grep( $arr, sub
    {
        my( $n, $i ) = @_;
        return( $n != 5 && $i > 4 );
    });
    # yields: 1, 9, 4, 7, 3, 8, 6, 9, 1
    is( "@$arr", '1, 9, 4, 7, 3, 8, 6, 9, 1', 'grep not 5 and great than 4' );

    $arr = xQuery->grep( $arr, sub
    {
        my( $a ) = @_;
        return( $a != 9 );
    });
    # yields: 1, 4, 7, 3, 8, 6, 1
    is( "@$arr", '1, 4, 7, 3, 8, 6, 1', 'grep except 9' );

    # Using invert
    $arr = xQuery->grep( $arr, sub
    {
        my( $a ) = @_;
        return( $a == 9 );
    }, 1);
    # yields: 1, 4, 7, 3, 8, 6, 1
    is( "@$arr", '1, 4, 7, 3, 8, 6, 1', 'grep except 9 using invert' );

    # Filter an array of numbers to include only numbers bigger then zero:
    $arr = $.grep( [ 0, 1, 2 ], sub
    {
        my( $n, $i ) = @_;
        return( $n > 0 );
    });
    # yields: 1, 2
    is( "@$arr", '1, 2', 'grep greater than 0' );
};

subtest 'inArray' => sub
{
    my $i;
    $i = $.inArray( 5 + 5, [ "8", "9", "10", 10 . '' ] );
    is( $i, 2, 'inArray insensitive to digits or letters' );

    my $arr = [ 4, "Pete", 8, "John" ];
    $i = xQuery->inArray( "John", $arr );
    is( $i, 3, 'inArray searching for a word' );
    $i = xQuery->inArray( 4, $arr );
    is( $i, 0, 'inArray searching for an integer' );
    $i = xQuery->inArray( "Karl", $arr );
    is( $i, -1, 'inArray word not found' );
    $i = xQuery->inArray( "Pete", $arr, 2 );
    is( $i, -1, 'inArray word found, but not after specified fromIndex' );
};

subtest 'isArray' => sub
{
    ok( $.isArray([]), 'isArray' );
};

subtest 'isEmptyObject' => sub
{
    ok( xQuery->isEmptyObject({}), 'isEmptyObject' );
    ok( !xQuery->isEmptyObject({ foo => "bar" }), 'isEmptyObject' );
};

subtest 'isFunction' => sub
{
    sub stub {}
    my $objs = [
        sub{},
        { 'x' => 15, 'y' => 20 },
        undef,
        'stub',
        'sub',
    ];
    ok( xQuery->isFunction( $objs->[0] ), 'isFunction -> sub{}' );
    ok( !xQuery->isFunction( $objs->[1] ), 'isFunction -> $hash' );
    ok( !xQuery->isFunction( $objs->[2] ), 'isFunction -> undef' );
    ok( xQuery->isFunction( $objs->[3] ), 'isFunction -> "stub"' );
    ok( !xQuery->isFunction( $objs->[4] ), 'isFunction -> "sub"' );
};

subtest 'isNumeric' => sub
{
    # true (numeric)
    ok( $.isNumeric( "-10" ), '-10' );
    ok( $.isNumeric( "0" ), '"0"' );
    ok( $.isNumeric( 0xFF ), '0xFF' );
    ok( $.isNumeric( "0xFF" ), '"0xFF"' );
    ok( $.isNumeric( "8e5" ), '8e5' );
    ok( $.isNumeric( "3.1415" ), '3.1415' );
    ok( $.isNumeric( +10 ), '+10' );
    ok( $.isNumeric( 0144 ), 'octal 0144' );
    ok( $.isNumeric( 'nan' ), 'NaN' );
    ok( $.isNumeric( 'inf' ), 'Infinity' );
     
    # false (non-numeric)
    ok( !$.isNumeric( "-0x42" ), '-0x42' );
    ok( !$.isNumeric( "7.2acdgs" ), '7.2acdgs' );
    ok( !$.isNumeric( "" ), '""' );
    ok( !$.isNumeric( {} ), '{}' );
    ok( !$.isNumeric( undef ), 'undef' );
};

subtest 'isPlainObject' => sub
{
    ok( xQuery->isPlainObject({}), '{}' );
    ok( !xQuery->isPlainObject( "test" ), '"test"' );
};

subtest 'isWindow' => sub
{
    require HTML::Object::DOM::Window;
    require HTML::Object::DOM::Element::IFrame;
    my $window = HTML::Object::DOM::Window->new;
    my $iframe = HTML::Object::DOM::Element::IFrame->new;
    ok( $.isWindow( $window ), '$.isWindow( $window )' );
    ok( !$.isWindow( $iframe ), '$.isWindow( $iframe )' );
};

subtest 'makeArray' => sub
{
    my $blank = <<EOT;
<!DOCTYPE html>
<html lang="en-GB">
    <head>
        <meta charset="utf-8" />
        <title></title>
    </head>
    <body>
        <div>First</div>
        <div>Second</div>
        <div>Third</div>
        <div>Fourth</div>
    </body>
</html>
EOT
    my $parser = HTML::Object::DOM->new;
    SKIP:
    {
        my $doc = $parser->parse_data( $blank ) || do
        {
            skip( "Unable to parse blank html: " . $parser->error, 3 );
        };
        HTML::Object::DOM->set_dom( $doc );
        my $elems = $('div');
        my $arr = xQuery->makeArray( $elems );
        if( !defined( $arr ) )
        {
            diag( "Error: ", xQuery->error );
        }
        my @arr2 = reverse( @$arr );
        # $(@arr2, { xq_debug => 4 })->appendTo( 'body' );
        $(@arr2)->appendTo( 'body' );
        my $html = $('body')->html;
        $html =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//gs;
        # diag( $('body')->normalize_content->as_string );
        is( $html, q{<div>Fourth</div><div>Third</div><div>Second</div><div>First</div>}, 'makeArray' );
    };
};

subtest 'map' => sub
{
    my $arr = [ "a", "b", "c", "d", "e" ];
    local $" = ', ';
    $arr = xQuery->map( $arr, sub
    {
        my( $n, $i ) = @_;
        return( uc( $n ) . $i );
    });
    is( "@$arr", 'A0, B1, C2, D3, E4', 'map return 1 element' );
    $arr = $.map( $arr, sub
    {
        my( $a ) = @_;
        return( $a . $a );
    });
    is( "@$arr", 'A0A0, B1B1, C2C2, D3D3, E4E4', 'map return 1 element' );
    $arr = $.map( [ 0, 1, 2 ], sub
    {
        my( $n ) = @_;
        return( $n + 4 );
    });
    is( "@$arr", '4, 5, 6', 'map change number value' );
    $arr = $.map( [ 0, 1, 2 ], sub
    {
        my( $n ) = @_;
        return( $n > 0 ? $n + 1 : undef );
    });
    is( "@$arr", '2, 3', 'map chnge or remove' );
    $arr = $.map( [ 0, 1, 2 ], sub
    {
        my( $n ) = @_;
        return( [ $n, $n + 1 ] );
        # You can also return as a list
        # return( $n, $n + 1 );
    });
    is( "@$arr", '0, 1, 1, 2, 2, 3', 'map with returned array' );
    my $dimensions = { width => 10, height => 15, length => 20 };
    $arr = $.map( $dimensions, sub
    {
        my( $value, $key ) = @_;
        return( $value * 2 );
    });
    @$arr = sort( @$arr );
    is( "@$arr", '20, 30, 40', 'map hash' );

    $arr = $.map( $dimensions, sub
    {
        my( $value, $key ) = @_;
        return( $key );
    });
    @$arr = sort( @$arr );
    is( "@$arr", 'height, length, width', 'map hash' );
    my $array = [ 0, 1, 52, 97 ];
    $arr = $.map( $array, sub
    {
        my( $a, $index ) = @_;
        return( [ $a - 45, $index ] );
        # You can also return as a list
        # return( $a - 45, $index );
    });
    is( "@$arr", '-45, 0, -44, 1, 7, 2, 52, 3', 'map with returned array' );
};

subtest 'merge' => sub
{
    my $arr;
    local $" = ', ';
    $arr = $.merge( [ 0, 1, 2 ], [ 2, 3, 4 ] );
    is( "@$arr", '0, 1, 2, 2, 3, 4', 'merge' );

    $arr = $.merge( [ 3, 2, 1 ], [ 4, 3, 2 ] );
    is( "@$arr", '3, 2, 1, 4, 3, 2', 'merge' );

    my $first  = [ "a", "b", "c" ];
    my $second = [ "d", "e", "f" ];
    $arr = $.merge( $.merge( [], $first ), $second );
    is( "@$arr", 'a, b, c, d, e, f', 'merge' );
};

subtest 'now' => sub
{
    my $t = $.now();
    isa_ok( $t => 'DateTime', 'now returns a DateTime object' );
    like( "$t", qr/^\d{10}$/, 'now stringifies to digits' );
};

subtest 'parseHTML' => sub
{
    my $str = "hello, <b>my name is</b> xQuery.";
    my $html = $.parseHTML( $str );
    # diag( "Value returned contains ", $html->length, " elements: ", $html->join( ', ' ) );
    my $nodeNames = [];
    # local $xQuery::DEBUG = 4;
    $.each( $html, sub
    {
        my( $i, $el ) = @_;
        $nodeNames->[$i] = $el->nodeName;
    }) || die( "Error: ", $xQuery::ERROR );
    
    is( join( ', ', @$nodeNames ), '#text, b, #text', 'parseHTML' );
};

subtest 'parseJSON' => sub
{
    my $ref = $.parseJSON( '{ "name": "John" }' );
    is( $ref->{name}, 'John', 'parseJSON' );
};

subtest 'parseXML' => sub
{
    my $str = <<EOT;
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
    # try-catch
    local $@;
    eval
    {
        require XML::LibXML;
    };
    SKIP:
    {
        if( $@ )
        {
            skip( "XML::LibXML is not installed", 1 );
        }
        my $doc = $.parseXML( $str );
        diag( "Error parsing: ", $xQuery::ERROR ) if( !defined( $doc ) );
        isa_ok( $doc => 'XML::LibXML::Document', 'parseXML' );
    };
};

subtest 'removeData' => sub
{
    my $div = $('<div />');
    is( $div->data( 'test1' ) => undef, 'removeData -> no value set yet' );
    $.data( $div, 'test1', 'VALUE-1' );
    diag( "Error setting value for test1: ", $xQuery::ERROR ) if( $xQuery::ERROR );
    $.data( $div, 'test2', 'VALUE-2' );
    is( $.data( $div, 'test1' ) => 'VALUE-1', 'removeData -> value 1 set' );
    $.removeData( $div, 'test1' );
    is( $.data( $div, 'test1' ) => undef, 'removeData -> value 1 removed' );
    is( $.data( $div, 'test2' ) => 'VALUE-2', 'removeData -> value 2 set' );
};

subtest 'trim' => sub
{
    my $str = "         lots of spaces before and after         ";
    is( $.trim($str), 'lots of spaces before and after', 'trim' );
};

subtest 'type' => sub
{
    is( $.type( undef ), 'undef', 'type -> undef' );
    is( $.type( () ), 'undef', 'type -> undef' );
    is( $.type( {} ), 'hash', 'type -> hash' );
    is( $.type( [] ), 'array', 'type -> array' );
    is( $.type( HTML::Object::XQuery->new_array ), 'array', 'type -> array' );
    local $@;
    # try-catch
    eval
    {
        require DateTime;
    };
    SKIP:
    {
        if( $@ )
        {
            skip( "DateTime is not installed", 1 );
        }
        is( $.type( DateTime->now ), 'date', 'type -> date' );
    };
    is( $.type( HTML::Object::XQuery->true ), 'boolean', 'type -> boolean' );
    is( $.type( qr/test/ ), 'regexp', 'type -> regexp' );
    require HTML::Object::Exception;
    is( $.type( HTML::Object::Exception->new( 'Oops' ) ), 'error', 'type -> error' );
    is( $.type( HTML::Object::XQuery->new_number(10) ), 'number', 'type -> number' );
    is( $.type( 10 ), 'number', 'type -> number' );
    is( $.type( 'Hello' ), 'string', 'type -> string' );
    is( $.type( HTML::Object::XQuery->new_scalar( 'Hello' ) ), 'string', 'type -> string' );
};

subtest 'unique' => sub
{
    my $str = <<EOT;
<!DOCTYPE html>
<html lang="en-GB">
    <head>
        <meta charset="utf-8" />
        <title></title>
    </head>
    <body>
        <div>There are 6 divs in this document.</div>
        <div></div>
        <div class="dup"></div>
        <div class="dup"></div>
        <div class="dup"></div>
        <div></div>
    </body>
</html>
EOT
    HTML::Object::DOM->set_dom( $str );
    my $doc = HTML::Object::DOM->get_dom;
    my $divs = $('div')->get();
    # Add 3 elements of class dup too (they are divs)
    $divs = $divs->concat( $('.dup')->get() );
    is( $divs->length, 9, 'before unique' );
    # diag( "Pre-unique there are " . $divs->length . " elements." );
    $divs = $.unique( $divs );
    # diag( "Post-unique there are " . $divs->length . " elements." );
    is( $divs->length, 6, 'after unique' );
};

subtest 'uniqueSort' => sub
{
    my $str = <<EOT;
<!DOCTYPE html>
<html lang="en-GB">
    <head>
        <meta charset="utf-8" />
        <title></title>
    </head>
    <body>
        <div>There are 6 divs in this document.</div>
        <div></div>
        <div class="dup"></div>
        <div class="dup"></div>
        <div class="dup"></div>
        <div></div>
    </body>
</html>
EOT
    HTML::Object::DOM->set_dom( $str );
    my $doc = HTML::Object::DOM->get_dom;
    my $divs = $('div')->get();
    # Add 3 elements of class dup too (they are divs)
    $divs = $divs->concat( $('.dup')->get() );
    is( $divs->length, 9, 'before unique' );
    diag( "Pre-unique there are " . $divs->length . " elements." );
    $divs = $.uniqueSort( $divs );
    diag( "Post-unique there are " . $divs->length . " elements." );
    is( $divs->length, 6, 'after unique' );
};

done_testing();

__END__

