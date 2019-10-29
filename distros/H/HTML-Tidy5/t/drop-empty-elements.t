#!perl -T

use 5.010001;
use warnings;
use strict;

use Test::More tests => 3;

use HTML::Tidy5;

use lib 't';

use TidyTestUtils;

my $html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title></title>
    </head>
    <body>
        <span class="empty"></span>
    </body>
</html>
HTML

subtest 'default constructor warns about empty spans' => sub {
    plan tests => 2;

    my $tidy = HTML::Tidy5->new;
    isa_ok( $tidy, 'HTML::Tidy5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy,
        [ 'test (7:9) Warning: trimming empty <span>' ],
    );
};

subtest 'drop_empty_elements => 1 gives message' => sub {
    plan tests => 2;

    my $tidy = HTML::Tidy5->new( { drop_empty_elements => 1 } );
    isa_ok( $tidy, 'HTML::Tidy5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy,
        [ 'test (7:9) Warning: trimming empty <span>' ],
    );
};

subtest 'drop_empty_elements => 0 gives no messages' => sub {
    plan tests => 2;

    my $tidy = HTML::Tidy5->new( { drop_empty_elements => 0 } );
    isa_ok( $tidy, 'HTML::Tidy5' );
    $tidy->parse( 'test', $html );

    messages_are( $tidy, [] );
};

exit 0;
