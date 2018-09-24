#!perl -T

use 5.010001;
use warnings;
use strict;

use Test::More tests => 4;

use HTML::T5;

my $html = join '', <DATA>;

my $tidy = HTML::T5->new;
isa_ok( $tidy, 'HTML::T5' );

$tidy->ignore( type => TIDY_INFO );
my $rc = $tidy->parse( '-', $html );
ok( $rc, 'Parsed OK' );

my @messages = $tidy->messages;
is( scalar @messages, 6, 'Right number of initial messages' );

$tidy->clear_messages;
is_deeply( [$tidy->messages], [], 'Cleared the messages' );

__DATA__
<html>
    <body><head>blah blah</head>
        <title>Barf</title>
        <body>
            <p>more blah
            </P>
        </body>
    </html>

