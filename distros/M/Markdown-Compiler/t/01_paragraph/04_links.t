#!/usr/bin/env perl
use Markdown::Compiler::Test;

build_and_test( "Autolinking HTTP Addresses", 
    "That one http://google.com/", [
    [ result_is => "<p>That one <a href=\"http://google.com/\">http://google.com/</a></p>\n\n" ],
]);

build_and_test( "Autolinking HTTP Addresses inside italics", 
    "That one _ http://google.com/ _", [
    [ result_is => "<p>That one <em> <a href=\"http://google.com/\">http://google.com/</a> </em></p>\n\n" ],
]);

build_and_test( "Link with title", 
    "This is [an example](http://example.com/ \"Title\") inline link.", [
    [ result_is => "<p>This is <a href=\"http://example.com/\" title=\"Title\">an example</a> inline link.</p>\n\n" ],
]);

build_and_test( "Link without title", 
    "[This link](http://example.net/) has no title attribute.", [
    [ result_is => "<p><a href=\"http://example.net/\">This link</a> has no title attribute.</p>\n\n" ],
]);

build_and_test( "Link with anchor text.", 
    "[This link](http://example.net/index.html#hello) has no title attribute.", [
    [ result_is => "<p><a href=\"http://example.net/index.html#hello\">This link</a> has no title attribute.</p>\n\n" ],
]);

build_and_test( "This took a while...",
    'First, check out the [DBIx::Class::Schema::Config Documentation](https://github.com/symkat/DBIx-Class-Schema-Config' .
    '/blob/master/README.pod).  Questions like "[how do I change where it looks for configuration files?](https://metacp' .
    'an.org/module/DBIx::Class::Schema::Config#CHANGE-CONFIG-PATH)," and "[can I make programatic changes to the credent' .
    'ials before they\'re loaded?](https://metacpan.org/module/DBIx::Class::Schema::Config#filter_loaded_credentials)," ' .
    'are answered.', [ 
        [ result_is => '<p>First, check out the <a href="https://github.com/symkat/DBIx-Class-Schema-Config/blob/master/' .
            'README.pod">DBIx::Class::Schema::Config Documentation</a>.  Questions like "<a href="https://metacpan.org/m' .
            'odule/DBIx::Class::Schema::Config#CHANGE-CONFIG-PATH">how do I change where it looks for configuration file' .
            's?</a>," and "<a href="https://metacpan.org/module/DBIx::Class::Schema::Config#filter_loaded_credentials">c' .
            'an I make programatic changes to the credentials before they\'re loaded?</a>," are answered.</p>' . "\n\n"
        ],
    ]

);

build_and_test("Links in lists",
    '* [Example](http://example.com/)', [
        [ result_is => "<ul>\n<li><a href=\"http://example.com/\">Example</a></li>\n\n</ul>\n" ],
    ],
);

#We'll need some more work on header parsing for this test to work
build_and_test("Links in headers",
    '# [Example](http://example.com/)', [
        [ result_is => "<h1><a href=\"http://example.com/\">Example</a></h1>\n\n" ],
    ],
);

done_testing;
