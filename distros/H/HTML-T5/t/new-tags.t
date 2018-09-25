#!perl -T

use 5.010001;
use warnings;
use strict;

BEGIN
{
    $ENV{LC_ALL} = 'C';
};

use Test::More tests => 4;

use HTML::T5;

use lib 't';

use TidyTestUtils;

my $html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title></title>
    </head>
    <body>
        <newblock>
            <p>
                This is a nav section
            </p>
        </newblock>
        <otherblock>
            <p>
                This is an <newinline>otherblock</newinline>.
            </p>
        </otherblock>
    </body>
</html>
HTML

my @all_errors = (
    'test (7:9) Error: <newblock> is not recognized!',
    'test (7:9) Warning: discarding unexpected <newblock>',
    'test (11:9) Warning: discarding unexpected </newblock>',
    'test (12:9) Error: <otherblock> is not recognized!',
    'test (12:9) Warning: discarding unexpected <otherblock>',
    'test (14:28) Error: <newinline> is not recognized!',
    'test (14:28) Warning: discarding unexpected <newinline>',
    'test (14:49) Warning: discarding unexpected </newinline>',
    'test (16:9) Warning: discarding unexpected </otherblock>',
);


subtest 'default constructor warns about <nav> tag' => sub {
    plan tests => 2;

    my $tidy = HTML::T5->new;
    isa_ok( $tidy, 'HTML::T5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy, [ @all_errors ] );
};


subtest 'Only add new blocklevel' => sub {
    plan tests => 2;

    my $tidy = HTML::T5->new( { 'new-blocklevel-tags' => 'newblock,otherblock' } );
    isa_ok( $tidy, 'HTML::T5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy, [ grep { !/block/ } @all_errors ], 'Excluded the block errors' );
};


subtest 'Only add new inline' => sub {
    plan tests => 2;

    my $tidy = HTML::T5->new( { 'new-inline-tags' => 'newinline' } );
    isa_ok( $tidy, 'HTML::T5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy, [ grep { !/inline/ } @all_errors ], 'Excluded the inline errors' );
};


subtest 'Add new line and blocklevel' => sub {
    plan tests => 2;

    my $tidy = HTML::T5->new( {
        'new-blocklevel-tags' => 'newblock,otherblock',
        'new-inline-tags'     => 'newinline',
    } );
    isa_ok( $tidy, 'HTML::T5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy, [], 'Quieted all errors' );
};

exit 0;
