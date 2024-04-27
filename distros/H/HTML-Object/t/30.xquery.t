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
    use_ok( 'HTML::Object::DOM', qw( global_dom 1 ) ) || BAIL_OUT( "Cannot load HTML::Object::DOM" );
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

subtest 'load' => sub
{
    my $div = $('<div />', { id => 'hello' } );
    my $f = file( "./t/test_load.html" );
    $div->load( $f->uri ) || do
    {
        diag( "Error loading $f into div: ", $div->error ) if( $DEBUG );
    };
    diag( $div->as_string ) if( $DEBUG );
    is( $div->children->length, 1, 'div # of children' );
    
    my $f2 = "./t/test_load2.html";
    my $parser = HTML::Object::DOM->new;
    SKIP:
    {
        my $page = $parser->parse_file( $f2 ) || do
        {
            skip( "Unable to parse $f2: " . $parser->error, 5 );
        };
        if( !$parser->_load_class( 'LWP::UserAgent', { version => '6.49' } ) ||
            !$parser->_load_class( 'URI', { version => '1.74' } ) )
        {
            skip( "LWP::UserAgent and URI are required for those tests.", 5 );
        }
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

done_testing();

__END__

