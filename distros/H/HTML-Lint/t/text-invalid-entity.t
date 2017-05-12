#!perl

use warnings;
use strict;

require 't/LintTest.pl';

checkit( [
    [ 'text-unknown-entity' => qr/Entity &metalhorns; is unknown/ ],
    [ 'text-invalid-entity' => qr/Entity &#8675309; is invalid/ ],
    [ 'text-invalid-entity' => qr/Entity &#xdeadbeef; is invalid/ ],
    [ 'text-unknown-entity' => qr/Entity &xdeadbeef; is unknown/ ],
], [<DATA>] );

__DATA__
<html>
    <head>
        <title>Ace of &spades;: A tribute to Mot&ouml;rhead. &#174; &metalhorns;</title>
        <script>
            function foo() {
                if ( 6 == 9 && 25 == 6 ) {
                    x = 14;
                }
            }
        </script>
    </head>
    <body bgcolor="white">
        <p>
        Thanks for visiting Ace of &#9824; <!-- Numeric version of &spades; -->
        <p>
        Ace of &#x2660; is your single source for everything related to Mot&ouml;rhead.
        <p>
        Here's an icon of my girlfriend Jenny: &#8675309; <!-- invalid because we cap at 65536 -->
        <p>
        And here's an icon of a deceased cow: &#xdeadbeef; <!-- Invalid because we cap at xFFFF -->
        <p>
        Another deceased cow: &xdeadbeef; <!-- Not a valid hex entity, but unknown to our lookup tables -->
        <p>
        Here's an awesome link to <a href="http://www.youtube.com/watch?v=8yLhA0ROGi4&feature=related">"You Better Swim"</a> from the SpongeBob movie.
        <!--
        Here in the safety of comments, we can put whatever &invalid; and &malformed entities we want, &
        nobody can stop us.  Except maybe Cheech & Chong.
        -->
    </body>
</html>
