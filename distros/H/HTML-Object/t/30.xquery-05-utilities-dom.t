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

# jQuery utility methods - DOM-dependent (each subtest sets up its own DOM tree)

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
