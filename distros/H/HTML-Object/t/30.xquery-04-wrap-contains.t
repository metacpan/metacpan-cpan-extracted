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

# Wrapping, containment, extend, grep/filter utilities

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


done_testing();

__END__
