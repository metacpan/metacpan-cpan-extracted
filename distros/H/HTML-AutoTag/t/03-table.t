#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

use HTML::AutoTag;

my $auto = HTML::AutoTag->new( indent => '    ' );
my %tr_attr = ( class => [qw(odd even)] );

is $auto->tag(
    tag => 'table',
    attr => { class => 'spreadsheet' },
    cdata => [
        {
            tag => 'tr',
            attr => \%tr_attr,
            cdata => {
                tag => 'td',
                attr => { style => { color => [qw(red green)] } },
                cdata => [qw(one two three four five six)],
            },
        },
        {
            tag => 'tr',
            attr => \%tr_attr,
            cdata => {
                tag => 'td',
                attr => { style => { color => [qw(red green)] } },
                cdata => [qw(seven eight nine ten eleven twelve)],
            },
        },
        {
            tag => 'tr',
            attr => \%tr_attr,
            cdata => {
                tag => 'td',
                attr => { style => { color => [qw(red green)] } },
                cdata => [qw(thirteen fourteen fifteen sixteen seventeen eighteen)],
            },
        },
    ]
), '<table class="spreadsheet">
    <tr class="odd">
        <td style="color: red">one</td>
        <td style="color: green">two</td>
        <td style="color: red">three</td>
        <td style="color: green">four</td>
        <td style="color: red">five</td>
        <td style="color: green">six</td>
    </tr>
    <tr class="even">
        <td style="color: red">seven</td>
        <td style="color: green">eight</td>
        <td style="color: red">nine</td>
        <td style="color: green">ten</td>
        <td style="color: red">eleven</td>
        <td style="color: green">twelve</td>
    </tr>
    <tr class="odd">
        <td style="color: red">thirteen</td>
        <td style="color: green">fourteen</td>
        <td style="color: red">fifteen</td>
        <td style="color: green">sixteen</td>
        <td style="color: red">seventeen</td>
        <td style="color: green">eighteen</td>
    </tr>
</table>
',
    "correct HTML";
