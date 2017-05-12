#!/usr/bin/perl
use strict;
use warnings;
use blib;
use HTML::Template::Compiled 0.73;
use HTML::Template::Compiled::Plugin::InlineImage;
use Fcntl qw(:seek);

# ---------- Image --------------
my $data;
{
    open my $fh, "examples/punk_smiley.gif" or die $!;
    local $/;
    $data = <$fh>;
}

# ---------- HTC ----------------
my ($template, $script);
#$HTML::Template::Compiled::Plugin::InlineImage::SIZE_WARNING = 0;
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
    raw => $data,
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
<br>GIF:  <img <%= raw escape=INLINE_IMG_GIF %> alt="test">

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
