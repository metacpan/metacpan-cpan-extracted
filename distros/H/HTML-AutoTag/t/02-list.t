#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

use HTML::AutoTag;

my $auto = HTML::AutoTag->new( indent => '    ' );
my %attr = ( class => [qw(odd even)] );
my @data = qw( one two three four five six seven eight );
is $auto->tag(
    tag   => 'ol', 
    cdata => [
        map { tag => 'li', attr => \%attr, cdata => $_ }, @data
    ]
), '<ol>
    <li class="odd">one</li>
    <li class="even">two</li>
    <li class="odd">three</li>
    <li class="even">four</li>
    <li class="odd">five</li>
    <li class="even">six</li>
    <li class="odd">seven</li>
    <li class="even">eight</li>
</ol>
',
    "correct HTML";
