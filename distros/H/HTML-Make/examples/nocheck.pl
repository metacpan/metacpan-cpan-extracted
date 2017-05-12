#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make;
my $freaky = HTML::Make->new ('freaky', nocheck => 1);
$freaky->push ('franky', nocheck => 1, text => 'Visible man');
print $freaky->text ();

