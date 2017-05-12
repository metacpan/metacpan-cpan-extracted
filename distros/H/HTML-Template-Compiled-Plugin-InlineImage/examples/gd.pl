#!/usr/bin/perl
use strict;
use warnings;
use blib;
use GD;
use HTML::Template::Compiled 0.73;
use HTML::Template::Compiled::Plugin::InlineImage;
use Fcntl qw(:seek);

# ---------- GD --------------
# create a new image
my $im = new GD::Image( 100, 100 );

# allocate some colors
my $white = $im->colorAllocate( 255, 255, 255 );
my $black = $im->colorAllocate( 0,   0,   0 );
my $red   = $im->colorAllocate( 255, 0,   0 );
my $blue  = $im->colorAllocate( 0,   0,   255 );

# make the background transparent and interlaced
$im->transparent($white);
$im->interlaced('true');

# Put a black frame around the picture
$im->rectangle( 0, 0, 99, 99, $black );

# Draw a blue oval
$im->arc( 50, 50, 95, 75, 0, 360, $blue );

# And fill it with red
$im->fill( 50, 50, $red );

# make sure we are writing to a binary stream
# binmode STDOUT;
# Convert the image to PNG and print it on standard output
# my $bin = $im->png;

# ---------- HTC ----------------
my $template;
my $script;
$HTML::Template::Compiled::Plugin::InlineImage::SIZE_WARNING = 0;
{
    local $/;
    $template = <DATA>;
    seek DATA, 0, SEEK_SET;
    $script = <DATA>;
}
my $htc = HTML::Template::Compiled->new(
    scalarref => \$template,
    debug => 0,
    plugin => [qw(HTML::Template::Compiled::Plugin::InlineImage)],
);
$htc->param(
    gd => $im,
    template => $template,
    code => $script,
);
print $htc->output;

__DATA__

<html><head>
    <title>HTML::Template::Compiled::Plugin::InlineImage example</title>
</head>
<body bgcolor="#dddddd">

<h2>Images</h2>
<br>PNG:  <img <%= gd escape=INLINE_IMG %> alt="test">
<br>PNG:  <img <%= gd escape=INLINE_IMG_PNG %> alt="test">
<br>GIF:  <img <%= gd escape=INLINE_IMG_GIF %> alt="test">
<br>JPEG: <img <%= gd escape=INLINE_IMG_JPEG %> alt="test">

<hr>
<h2>The Template:</h2>
<table border=1 bgcolor="#ffffff"><tr><td>
<pre><%= template escape=html %></pre>
</td></tr></table>

<hr>
<h2>The whole script:</h2>
<table border=1 bgcolor="#ffffff"><tr><td>
<pre><%= code escape=html %></pre>
</td></tr></table>
</body></html>
