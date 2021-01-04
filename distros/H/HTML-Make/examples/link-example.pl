#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make;
my $element = HTML::Make->new ('p', text => 'Here is a ');
$element->push ('a', attr => {href => 'http://www.example.org/'}, text => 'link to example');
print $element->text ();

