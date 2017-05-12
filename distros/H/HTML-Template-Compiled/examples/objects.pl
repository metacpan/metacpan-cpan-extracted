#!/usr/bin/perl

package HTC::Object;
use strict;
use warnings;
use base qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(first last age));
sub fullname {
            my $first = $_[0]->get_first;
            my $last = $_[0]->get_last;
            return "$last, $first";
}

package main;
use strict;
use warnings;
use HTML::Template::Compiled;
use Fcntl qw(:seek);

my ($template, $perlcode);
{
    local $/;
    $template = <DATA>;
    seek DATA, 0, SEEK_SET;
    $perlcode = <DATA>;
}

my $htc = HTML::Template::Compiled->new(
    scalarref => \$template,
    tagstyle => [qw(+tt)],
    use_expressions => 1,
);
my $persons = [
    HTC::Object->new({first => 'Bart',   last => 'Simpson', age => 10, hair => 'yellow'}),
    HTC::Object->new({first => 'Maggie', last => 'Simpson', age => 10, hair => 'yellow'}),
    HTC::Object->new({first => 'March',  last => 'Simpson', age => 42, hair => 'purple'}),
    HTC::Object->new({first => 'Homer',  last => 'Simpson', age => 42, hair => 'none'}),
];
$htc->param(
    count => scalar @$persons,
    items => $persons,
    script => $0,
    perlcode => $perlcode,
    columns => [qw/ age hair /],
);
my $output = $htc->output;
print $output;

__DATA__
<html><head><title>HTC example with objects</title></head>
<body>
<h2>Script: [%= .script %]</h2><p>
Found [%= .count %] persons:
<table>
<tr><th>Name</th>[%loop .columns %]<th>[%= expr="ucfirst(_)" %]</th><%/loop %></tr>
[%loop items alias=person %]
<tr>
    <td>[%= fullname %]</td>
    [%loop .columns alias=column PRE_CHOMP=3 %]
    <td>[%= expr="person{column}" %]</td>
    [%/loop PRE_CHOMP=3 %]
</tr>
[%/loop items%]
</table>
<hr>
<h2>The Script:</h2>
<pre>
[%= perlcode escape=html %]
</pre>
</body></html>
