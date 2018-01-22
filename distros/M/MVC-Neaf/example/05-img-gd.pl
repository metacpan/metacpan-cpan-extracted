#!/usr/bin/env perl

# And example demonstrating raw content.
# This actually takes 1 line: return { -content => $foo, -type => 'bar' };
# Everything else is just decoration.

use strict;
use warnings;

use MVC::Neaf qw(:sugar);

# We must check that GD library is actually there, but not die if it's not
my $has_gd = eval {
    require GD::Simple;
    GD::Simple->read_color_table if $ENV{MOD_PERL};
    1;
};
# Deliberately skip exception handling

# Carrying our HTML & JS with us again
my $tpl = <<"HTML";
<html>
<head>
    <title>[% title | html %] - [% file | html %]</title>
</head>
<body>
<h1>[% title | html %]</h1>
[% IF has_gd %]
<script lang="javascript">
    "use strict";
    var x=10;
    var y=10;
    var draw = '[% root %]'+'/draw.png';

    function upd() {
        document.getElementById("image").src = draw + '?x='+x+'&y='+y;
        return false;
    };

    /* Some arithmetics to make scaling more natural */
    function inc(z) {
        return ( (z * 11)/10 ) | 0;
    };

    function dec(z) {
        return ( (z * 9)/10+1 ) | 0;
    };
</script>
<table border="0">
    <tr>
        <td align="right"><input type="submit" value="x--" onClick="x=dec(x); return upd()"></td>
        <td align="left"><input type="submit" value="x++" onClick="x=inc(x); return upd()"></td>
        <td></td>
    </tr>
    <tr>
        <td rowspan="2" colspan="2" align="center" valign="center">
            <img id="image" src="[% root %]/draw.png">
        </td>
        <td valign="bottom"><input type="submit" value="y--" onClick="y=dec(y); return upd()"></td>
    </tr>
    <tr>
        <td valign="top"><input type="submit" value="y++" onClick="y=inc(y); return upd()"></td>
    </tr>
</table>
[% ELSE # IF has_gd %]
<h2>Please install GD::Simple for this example to work</h2>
[% END  # IF has_gd %]
</body>
</html>
HTML

# The page is (almost) static, no logic here
get '/05/image' => sub {
    my $req = shift;

    return {};
}, default     => {
    -view          => 'TT',
    -template      => \$tpl,
    title          => 'Image & raw content demo',
    file           => "example/05 NEAF ".MVC::Neaf->VERSION,
    root           => '/05',
    has_gd         => $has_gd,
}, description => "Image & raw content";

# Don't offer image if no GD
$has_gd && get '/05/draw.png' => sub {
    my $req = shift;

    my $x = $req->param( x => '[1-9]\d+' ) || 10;
    my $y = $req->param( y => '[1-9]\d+' ) || 10;

    # Just some image making
    my $img = GD::Simple->new( $x, $y );
    $img->moveTo ( int($x/2), int($y/2) );
    $img->bgcolor('orange');
    $img->ellipse( $x, $y );

    return {
        # Next line is what file is for: returning raw content.
        # View processing won't happen here at all!
        -content => $img->png,
        -type    => 'image/png',
    };
};

neaf->run;
