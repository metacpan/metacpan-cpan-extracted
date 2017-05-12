#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make;
my $p = HTML::Make->new ('p', attr => {class => 'big'});
$p->add_attr (class => 'small');

