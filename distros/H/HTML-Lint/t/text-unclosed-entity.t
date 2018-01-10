#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'text-unclosed-entity' => qr/Entity &ouml; is missing its closing semicolon/ ],
    [ 'text-unclosed-entity' => qr/Entity &#63; is missing its closing semicolon/ ],
    [ 'text-unknown-entity'  => qr/Entity &middle is unknown/ ],
], [<DATA>] );

__DATA__
<html>
    <head>
        <title>Ace of &spades;: A tribute to Mot&ouml;rhead.</title>
        <script>
            function foo() {
                if ( 6 == 9 && 25 == 6 ) {
                    x = 14;
                }
            }
        </script>
    </head>
    <body bgcolor="white">
        Mot&ouml rhead rulez!
        &sup; &sup2; But can we find an unclosed entity at the end of the line &#63
        <p>
        What about unclosed unknown entities in the &middle of the line?
        Here's an awesome link to <a href="http://www.youtube.com/watch?v=8yLhA0ROGi4&amp;feature=related">"You Better Swim"</a> from the SpongeBob movie.
        <!--
        Here in the safety of comments, we can put whatever &invalid; and &malformed entities we want, &
        nobody can stop us.  Except maybe Cheech & Chong.
        -->
    </body>
</html>
