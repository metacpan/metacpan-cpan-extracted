#!/usr/bin/env perl

use strict;
use warnings;

use HTML::Entities::Interpolate;

# ------------------------------

my($block_1) = '<p>Para One</p>';
my($block_2) = "<p align='center'>Para Two</p>";
my($block_3) = 'http://tipjar.com/bin/test?foo=bar&reg=inald';
my($block_4) = $Entitize{$block_3};

print <<EOS;
<html>
    <head>
        <title>Test HTML::Entities::Interpolate</title>
    </head>
    <body>
        <h1 align='center'>HTML::Entities::Interpolate</h1>
        <form action='#'>
        <table align='center'>
        <tr>
            <td align='center'>Input: <input name='data' value='$Entitize{$block_1}'></td>
        </tr>
        <tr>
            <td align='center'><br>The full text of the block is <pre>$Entitize{$block_2}</pre></td>
        </tr>
        <tr>
            <td align='center'><br>Check out the web page at: <a href='$block_3'>$block_4</a></td>
        </tr>
        </table>
        </form>
    </body>
</html>
EOS
