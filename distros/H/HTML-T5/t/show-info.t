#!perl -T

BEGIN
{
    $ENV{LC_ALL} = 'C';

    # See: https://github.com/shlomif/html-tidy5/issues/6
    $ENV{LANG} = 'en_US.UTF-8';
};


use 5.010001;
use warnings;
use strict;

use Test::More skip_all => "failure in recent libtidy 5";

use HTML::T5 ();

use lib 't';

use TidyTestUtils;

my $html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title></title>
    </head>
    <body id=foo>
    </body>
</html>
HTML

subtest 'default constructor shows info' => sub {
    plan tests => 2;

    my $tidy = HTML::T5->new;
    isa_ok( $tidy, 'HTML::T5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy,
        [ 'test (6:5) Info: value for attribute "id" missing quote marks' ]
    );
};

subtest 'show_info => 1 shows info' => sub {
    plan tests => 2;

    my $tidy = HTML::T5->new( { show_info => 1 } );
    isa_ok( $tidy, 'HTML::T5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy,
        [ 'test (6:5) Info: value for attribute "id" missing quote marks' ]
    );
};

subtest 'show_info => 0' => sub {
    plan tests => 2;

    my $tidy = HTML::T5->new( { show_info => 0 } );
    isa_ok( $tidy, 'HTML::T5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy, [] );
};

exit 0;
