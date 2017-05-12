
use strict;
use Test::More tests => 15;

BEGIN { $^W = 1 }

use HTML::StripScripts;
my $f = HTML::StripScripts->new;

mytest( '',      '<!--filtered-->', 'reject null' );
mytest( '<>',    '<!--filtered-->', 'reject empty' );
mytest( '<->',   '<!--filtered-->', 'reject malformed' );
mytest( '<foo>', '<!--filtered-->', 'reject unknown' );
mytest( '<i />', '<i></i>',         'ignore trailing junk' );
mytest( '<img alt="foo" alt="bar" />',
        '<img alt="bar" />',
    'overwrite repeated values' );
mytest( '<img align="right"alt="bar" />',
        '<img align="right" alt="bar" />',
    'allow squashed values' );

mytest( q{<img alt='foo'>},      '<img alt="foo" />',           'accept singlequotes' );
mytest( '<img alt=foo>',         '<img alt="foo" />',           'accept unquoted' );
mytest( q{<img alt='&lt;foo'>},  '<img alt="&lt;foo" />',       'allow &lt in singlequotes' );
mytest( '<img alt="&lt;foo">',   '<img alt="&lt;foo" />',       'allow &lt in doublequotes' );
mytest( '<img alt=&lt;foo>',     '<img alt="&amp;lt;foo" />',   'reject unquoted entity' );
mytest( '<img alt="&foo-bar;">', '<img alt="&amp;foo-bar;" />', 'reject malformed entity' );

mytest( '<hr noshade>',   '<hr noshade="noshade" />', 'accept valueless attribute' );
mytest( '<hr noshade=1>', '<hr noshade="noshade" />', 'rewrite valueless attribute' );

sub mytest {
    my ($in, $out, $name) = @_;

    $f->input_start_document;
    $f->input_start($in);
    $f->input_end_document;
    is( $f->filtered_document, $out, "input_start $name" );
}

