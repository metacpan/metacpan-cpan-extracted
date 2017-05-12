#!/usr/bin/perl

use strict;
use warnings;

use HTML::TreeStructured;
use Data::Dumper;
use CGI;

my $tree1_default = <<EOF;
\$tree1 = [
     ['aaa',        color => 'green', url => 'http://www.perl.com/'],
     ['aaa/bbb',     mouseover => 'This is addl info'],
     ['aaa/xxx',    highlight => 'ff77cc'],
     ['aaa/ccc',    color => 'red', active => 0],
     ['bbb/ccc/ddd/eee/fff'],
     ['bbb'],
     ['bbb/ccc/ddd/eee', comment => 'Ok'],
     ['bbb/CCC/ddd/eee/fff'],
     ['ccc/aaa/ddd/eee/fff/g/h', color => 'red'],
     ['ccc', color => 'blue', highlight => 'ffcc77', mouseover => 'Hello'],
     ['ddd', color => 'blue', highlight => 'ffcc77', mouseover => 'Hello'],
     ['eee', color => 'green', highlight => 'ffcc77', mouseover => 'Hello eee'],
]
EOF

my $tree2_default = <<EOF;
\$tree2 = {
    aaa => {
        color    => 'red',
        bbb    => {
            color => 'green',
        },
        ccc    => {
            color => 'blue',
            ddd    => {
                url    => 'http://www.perl.com/',
            },
        },
    },
    xxx => {
        color    => 'red',
    },
}
EOF

print <<EOF;
Content-Type: text/html

<h4>HTML::TreeStructured Demo Script</h4>
Demonstrates that one can specify tree via arrayref or hashref.
<br>See <b>perldoc HTML::TreeStructured</b> for more details.
<hr>
EOF

my $q = new CGI;

my $tree1 = $q->param('tree1') || $tree1_default;
my $tree2 = $q->param('tree2') || $tree2_default;

print <<EOF;
<form method=post>
<center>
<table border=1 cellspacing=0 cellpadding=5>
<tr>
<td>
<textarea name=tree1 rows=10 cols=80>
$tree1
</textarea>
</td>
</tr>
<tr>
<td>
<textarea name=tree2 rows=10 cols=80>
$tree2
</textarea>
</td>
</tr>
<tr>
<td align=center>
<input type=submit>
</td>
</tr>
</table>
</center>
</form>
<hr>
EOF

my $tree1_html = HTML::TreeStructured->new(
     name         => 'tree_name',
     image_path   => 'images/',
     data         => eval($tree1),
     title        => "Tree1",
     title_width  => 300,
     level        => {},          ### If scalar, close BEYOND given depth. Depth starts from ZERO
)->output;

my $tree2_html = HTML::TreeStructured->new(
     name         => 'dir_name',
     image_path   => 'images/',
     data         => eval($tree2),
     title        => "Tree2",
     title_width  => 300,
     use_highlight => 1,
     level        => {},      ### If scalar, close BEYOND given depth. Count start from ZERO
                 ### If Hash, close for depths specified in keys
)->output;


print <<EOF;

<center>
<table border=1 cellspacing=0 cellpadding=5>
<tr>
<td valign=top>
$tree1_html
</td>
<td valign=top>
$tree2_html
</td>
</tr>
</table>
</center>
EOF
