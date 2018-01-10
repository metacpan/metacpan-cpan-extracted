#!perl

use warnings;
use strict;

use lib 't/';
use Util;

checkit( [
    [ 'text-unknown-entity' => qr/Entity &metalhorns; is unknown/ ],
], [<DATA>] );

__DATA__
<html>
    <head>
        <title>Ace of &spades;: A tribute to Mot&ouml;rhead. &#174; &metalhorns;</title>
    </head>
    <body bgcolor="white">
        Thanks for visiting Ace of &#9824; <!-- Numeric version of &spades; -->
        <p>
        Here's an awesome link to <a href="http://www.youtube.com/watch?v=8yLhA0ROGi4&amp;feature=related">"You Better Swim"</a> from the SpongeBob movie.
        <!--
        Here in the safety of comments, we can put whatever &invalid; and &malformed entities we want, &
        nobody can stop us.  Except maybe Cheech & Chong.
        -->
    </body>
</html>
