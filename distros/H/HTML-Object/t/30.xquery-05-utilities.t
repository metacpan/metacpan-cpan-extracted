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

# jQuery utility methods

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
