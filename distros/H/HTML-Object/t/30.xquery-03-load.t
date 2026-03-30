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

# Remote/file fragment loading via HTTP::Promise

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
        ok( $page, "parsed ./t/test_load2.html" );
        HTML::Object::DOM->set_dom( $page );
        my $frag_source = file("./t/test_load_fragment.html");
        my $frag_uri = $frag_source->uri;
        diag( "Loading fragment URI '$frag_uri'." ) if( $DEBUG );
        my $status;
        my $elem = $( "#new-projects", { xq_debug => $DEBUG } )->load( "$frag_uri #projects li", sub
        {
            my( $content, $textStatus, $respObject ) = @_;
            diag( "Called back with ", CORE::length( $content // '' ), " bytes of content, response status set to '", ( $textStatus // 'undef' ), "' and response object '", ( $respObject // 'undef' ), "'" ) if( $DEBUG );
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
