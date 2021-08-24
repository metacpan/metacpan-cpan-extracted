#!/usr/bin/env perl
use Markdown::Compiler::Test;

build_and_test( "Inline image", 
    'This is !http://example.com/image.jpeg inline image.', [
    [ result_is => '<p>This is <img src="http://example.com/image.jpeg" alt="http://example.com/image.jpeg"> inline image.</p>' . "\n\n" ],
]);

build_and_test( "Inline image", 
    'This is !http://example.com/image.jpeg inline image.', [
    [ result_is => '<p>This is <img src="http://example.com/image.jpeg" alt="http://example.com/image.jpeg"> inline image.</p>' . "\n\n" ],
]);

build_and_test( "Image with title", 
    'This is ![an example](http://example.com/image.jpeg "Title") inline image.', [
    [ result_is => '<p>This is <img src="http://example.com/image.jpeg" title="Title" alt="an example"> inline image.</p>' . "\n\n" ],
]);

build_and_test( "Image without title", 
    '![This image](http://example.net/image.jpeg) has no title attribute.', [
    [ result_is => '<p><img src="http://example.net/image.jpeg" alt="This image"> has no title attribute.</p>' ."\n\n" ],
]);

done_testing;
