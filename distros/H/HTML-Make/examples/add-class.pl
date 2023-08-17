#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make;
my $p = HTML::Make->new ('p', class => 'top');
$p->add_class ('help');
print $p->text ();

