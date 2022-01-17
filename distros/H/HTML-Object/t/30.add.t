#!perl
BEGIN
{
    #use strict;
    #use warnings;
    use Test::More;
    use Scalar::Util ();
};

BEGIN
{
    use_ok( 'HTML::Object', qw( global_dom 1 ) ) || BAIL_OUT( "Cannot load HTML::Object" );
    use_ok( 'HTML::Object::Element' ) || BAIL_OUT( "Cannot load HTML::Object::Element" );
    use_ok( 'HTML::Object::XQuery' ) || BAIL_OUT( "Cannot load HTML::Object::XQuery" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

$HTML::Object::FATAL_ERROR = 0;
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
    # my $dom = HTML::Object::DOM->get_dom;
    # $dom->debug( $DEBUG );
    # $HTML::Object::GLOBAL_DOM->debug(4);
    # $XML::XPathEngine::DEBUG = 4;
    # my $elem = $( "div" )->css( "border", "2px solid red" )->add( "p" )->css( "background", "yellow" );
    my $divs = $("div");
    diag( "Got divs: ", $divs->as_string( all => 1 ) ) if( $DEBUG );
    is( $divs->as_string( all => 1 ), q{<div></div><div></div><div></div><div></div><div></div><div></div>}, 'initial collection' );
    $divs->css( "border", "2px solid red" ) || do
    {
        diag( "Error found setting css: ", $divs->error ) if( $DEBUG );
    };
    diag( "Coloured divs: ", $divs->as_string( all => 1 ) ) if( $DEBUG );
    my $elem = $( "div" )->add( "p" )->css( "background", "yellow" );
#     my $elem = $divs->add( "p" );
    isa_ok( $elem, 'HTML::Object::Collection' );
    is( $elem->as_string( all => 1 ), q{<div style="border: 2px solid red; background: yellow;"></div><div style="border: 2px solid red; background: yellow;"></div><div style="border: 2px solid red; background: yellow;"></div><div style="border: 2px solid red; background: yellow;"></div><div style="border: 2px solid red; background: yellow;"></div><div style="border: 2px solid red; background: yellow;"></div><p style="background: yellow;">Added this... (notice no border)</p>}, 'p elements added' );
#     is( $elem->children->length, 7, 'collection children size' );

# 
#     $expect = <<EOT;
#         <div style="border: 2px solid red; background: yellow;"></div>
#         <div style="border: 2px solid red; background: yellow;"></div>
#         <div style="border: 2px solid red; background: yellow;"></div>
#         <div style="border: 2px solid red; background: yellow;"></div>
#         <div style="border: 2px solid red; background: yellow;"></div>
#         <div style="border: 2px solid red; background: yellow;"></div>
#  
#         <p style="background: yellow;">Added this... (notice no border)</p>
# EOT
#     chomp( $expect );
#     is( $elem->as_string, $expect, 'add elements then change css' );
};

done_testing();

__END__

