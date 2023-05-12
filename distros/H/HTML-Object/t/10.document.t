#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Scalar::Util ();
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( "Cannot load HTML::Object::DOM" );
    use_ok( 'HTML::Object::DOM::Document' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::Document" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $test = <<EOT;
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>document demo</title>
        <link rel="stylesheet" type="text/css" href="/some/sheet.css" crossorigin="anonymous" />
        <link rel="stylesheet" type="text/css" href="/some/other.css" crossorigin="anonymous" />
        <script type="text/javascript" src="/public/jquery-3.3.1.min.js" integrity="sha384-tsQFqpEReu7ZLhBV2VZlAu7zcOV+rXbYlF2cqB8txI/8aZajjp4Bqd+V6D5IgvKT"></script>
        <script type="text/javascript" src="/public/jquery-ui-1.11.4.js" integrity="sha384-YwCdhNQ2IwiYajqT/nGCj0FiU5SR4oIkzYP3ffzNWtu39GKBddP0M0waDU7Zwco0"></script>
    </head>
    <body>
        <div id="hello">Hello world!</div>
        <embed type="video/webm"
            src="/media/cc0-videos/flower.mp4"
            width="250"
            height="200"
        ></embed>
        <form name="test">
            <input name="name" type="text" />
        </form>
        <img src="/some/where.png" alt="Image 1" />
        <img src="/some/where2.png" alt="Image 2" />
        <a href="/some/where.html" target="_new">Click me</a>
        <a href="/some/where2.html" target="_new">Click me too </a>
        <a href="/some/where3.html" target="_new">Click me 3 !</a>
    </body>
</html>
EOT

my $test2 = <<EOT;
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>document demo2</title>
    </head>
    <body>
        <div>Hello world!</div>
    </body>
</html>
EOT

my $on_event_counter = {};
my $parser  = HTML::Object::DOM->new(
    onload => sub
    {
        my $evt = shift( @_ );
        isa_ok( $evt => 'HTML::Object::Event', 'onload event' );
        $on_event_counter->{onload}++;
        diag( "load event received. Document has been loaded." ) if( $DEBUG );
    },
    onreadystatechange => sub
    {
        my $evt = shift( @_ );
        isa_ok( $evt => 'HTML::Object::Event', 'onreadystatechange event' );
        $on_event_counter->{ $evt->detail->{state} }++;
        diag( "readystatechange event received. State is now: '", $evt->detail->{state}, "'" ) if( $DEBUG );
        like( $evt->detail->{state}, qr/^(loading|interactive|complete)$/, 'readystatechange state' );
        is( $evt->detail->{document}->readyState, $evt->detail->{state}, "\$doc->readyState eq '" . $evt->detail->{state} . "'" );
    },
);
isa_ok( $parser, 'HTML::Object::DOM' );
my $doc     = $parser->parse( $test );
isa_ok( $doc, 'HTML::Object::DOM::Document' );
my $parser2 = HTML::Object::DOM->new;
isa_ok( $parser2, 'HTML::Object::DOM' );
my $doc2    = $parser2->parse( $test2 );
isa_ok( $doc2, 'HTML::Object::DOM::Document' );

is( $on_event_counter->{onload}, 1, 'onload event' );
is( $on_event_counter->{loading}, 1, 'loading event' );
is( $on_event_counter->{interactive}, 1, 'interactive event' );
is( $on_event_counter->{complete}, 1, 'complete event' );

ok( !defined( $doc->activeElement ), 'activeElement' );

my $body = $doc->body;
isa_ok( $body, 'HTML::Object::DOM::Element', 'body' );

ok( !$doc->caretPositionFromPoint, 'caretPositionFromPoint' );

my $charset = $doc->characterSet;
is( $charset, 'utf-8', 'characterSet' );
# $doc2->debug( $DEBUG );
my $charset2 = $doc2->characterSet;
diag( "Got charset '$charset2'" ) if( $DEBUG );
is( $charset2, 'UTF-8', 'characterSet' );

ok( !$doc->compatMode, 'compatMode' );

my $mimeType = $doc->contentType;
is( $mimeType, 'text/html', 'default content type' );
$mimeType = $doc2->contentType;
is( $mimeType, 'text/html', 'actual content type' );
$doc->cookie = "foo=bar; pref=lang%3Den-GB; token=123456789";
is( $doc->cookie, "foo=bar; pref=lang%3Den-GB; token=123456789", 'cookie' );

my $att = $doc->createAttribute( 'data-dob', value => '1967-12-01' );
isa_ok( $att => 'HTML::Object::DOM::Attribute' );

my $elem = $doc->createElement( 'div' );
isa_ok( $elem => 'HTML::Object::DOM::Element', 'createElement' );

isa_ok( $doc->defaultView, 'HTML::Object::DOM::Window', 'defaultView' );

ok( !defined( $doc->designMode ), 'designMode' );

$doc->dir = 'ltr';
is( $doc->dir, 'ltr', 'dir' );

my $dtype = $doc->doctype;
isa_ok( $dtype, 'HTML::Object::Declaration' );
SKIP:
{
    if( !defined( $dtype ) )
    {
        skip( "no doctype found", 3 );
    }
    is( $dtype->name, 'html', 'doctype->name' );
    is( $dtype->publicId, '', 'doctype->publicId' );
    is( $dtype->systemId, '', 'doctype->systemId' );
};

my $html = $doc->documentElement;
isa_ok( $html, 'HTML::Object::DOM::Element', 'html' );
is( $html->tag, 'html' );

ok( !defined( $doc->documentURI ), 'documentURI' );

my $embeds = $doc->embeds;
isa_ok( $embeds, 'Module::Generic::Array', 'embeds return value' );
is( $embeds->length, 1, 'embeds' );

ok( !$doc->featurePolicy, 'featurePolicy' );
my $first = $doc->firstElementChild;
isa_ok( $first => 'HTML::Object::DOM::Element', 'firstElementChild return value' );
is( $first->tag, 'html', 'firstElementChild' );

ok( !$doc->fonts, 'fonts' );

my $forms = $doc->forms;
isa_ok( $forms, 'Module::Generic::Array', 'forms return value' );
is( $forms->length, 1, 'forms' );

ok( !$doc->fullscreenElement, 'fullscreenElement' );

my $div = $doc->getElementById( 'hello' );
isa_ok( $div => 'HTML::Object::DOM::Element' );
is( $div->getName, 'div', 'getElementById' );

my $root = $div->getRootNode;
is( $root, $doc, 'getRootNode' );

my $head = $doc->head;
isa_ok( $head => 'HTML::Object::DOM::Element', 'head' );

ok( !$doc->hidden, 'hidden' );

my $imgs = $doc->images;
isa_ok( $imgs, 'Module::Generic::Array', 'images return value' );
is( $imgs->length, 2, 'images' );

isa_ok( $doc->implementation, 'HTML::Object::DOM::Implementation', 'implementation' );

my $last = $doc->lastElementChild;
isa_ok( $first => 'HTML::Object::DOM::Element', 'lastElementChild return value' );
is( $first->tag, 'html', 'firstElementChild' );

ok( !defined( $doc->lastModified ), 'lastModified' );

my $links = $doc->links;
isa_ok( $links, 'Module::Generic::Array', 'links return value' );
is( $links->length, 3, 'links' );

ok( !defined( $doc->location ), 'location' );
ok( !defined( $doc->nodeValue ), 'nodeValue' );

ok( !defined( $doc->pictureInPictureElement ), 'pictureInPictureElement' );
ok( !defined( $doc->pictureInPictureEnabled ), 'pictureInPictureEnabled' );
isa_ok( $doc->plugins, 'HTML::Object::DOM::Collection', 'plugins' );
ok( !defined( $doc->pointerLockElement ), 'pointerLockElement' );
is( $doc->readyState, 'complete', 'readyState -> complete' );
ok( !defined( $doc->referrer ), 'referrer' );

my $scripts = $doc->scripts;
isa_ok( $scripts, 'Module::Generic::Array', 'scripts return value' );
is( $scripts->length, 2, 'scripts' );

ok( !defined( $doc->scrollingElement ), 'scrollingElement' );

ok( !defined( $doc->string_value ), 'string_value' );

my $sheets = $doc->styleSheets;
isa_ok( $sheets, 'Module::Generic::Array', 'styleSheets return value' );
is( $sheets->length, 2, 'styleSheets' );

ok( !defined( $doc->timeline ), 'timeline' );

is( $doc->title, 'document demo', 'title' );

ok( !defined( $doc->URL ), 'URL' );

is( $doc->visibilityState, 'visible', 'visibilityState' );

done_testing();

__END__

