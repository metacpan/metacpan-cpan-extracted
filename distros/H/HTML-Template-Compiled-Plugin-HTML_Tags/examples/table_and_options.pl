#!/usr/bin/perl
use strict;
use warnings;
use blib;
use HTML::Template::Compiled 0.81;
use HTML::Template::Compiled::Plugin::HTML_Tags;
use Fcntl qw(:seek);

# ---------- HTC ----------------
my $template;
my $script;
{
    local $/;
    $template = <DATA>;
    seek DATA, 0, SEEK_SET;
    $script = <DATA>;
}
my $htc = HTML::Template::Compiled->new(
    scalarref => \$template,
    debug => 1,
    plugin => [qw(HTML::Template::Compiled::Plugin::HTML_Tags)],
    tagstyle => [qw(+tt)],
);
$htc->param(
    options => [
        2, # selected
        [0, "Please choose"],
        [1, 'Jan'],
        [2, 'Feb'],
        [3, 'Mar'],
        [4, 'Apr'],
    ],
    table => [
        [qw(Perl-Version Age)],
        [0, 'embryo'],
        [1, 'infant'],
        [2, 'toddler'],
        [3, 'child'],
        [4, 'preteen'],
        [5, 'adolescent'],
    ],
    template => $template,
    code => $script,
);
print $htc->output;

__DATA__

<html><head>
    <title>HTML::Template::Compiled::Plugin::HTML_Tags example</title>
</head>
<body bgcolor="#dddddd">

Form:
<form>
<select name="foo">
[%HTML_OPTION options%]
</select>
</form>

Table:
[%HTML_TABLE table HEADER=1
TABLE_ATTR="bgcolor='black'"
TH_ATTR="bgcolor='green' align='center'"
TD_ATTR="bgcolor='white'"
TR_ATTR="bgcolor='yellow'"
%]

<hr>
<h2>The Template:</h2>
<table border=1 bgcolor="#ffffff"><tr><td>
<pre>[%= template escape=html %]</pre>
</td></tr></table>

<hr>
<h2>The whole script:</h2>
<table border=1 bgcolor="#ffffff"><tr><td>
<pre>[%= code escape=html %]</pre>
</td></tr></table>
</body></html>
