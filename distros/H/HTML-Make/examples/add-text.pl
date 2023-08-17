#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make;
my $element = HTML::Make->new ('p');
$element->add_text ('peanuts');
print $element->text ();


