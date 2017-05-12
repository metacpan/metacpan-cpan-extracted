#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make;
my $ol = HTML::Make->new ('ol');
$ol->multiply ('li', ['one', 'two', 'three']);
print $ol->text ();
