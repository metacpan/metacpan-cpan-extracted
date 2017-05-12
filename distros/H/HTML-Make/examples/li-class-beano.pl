#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make;
my $obj = HTML::Make->new ('li');
$obj->add_attr (class => 'beano');
print $obj->text ();


