#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make;
my $p = HTML::Make->new ('p', attr => {style => 'color:blue;'});
my $attr = $p->attr;
$attr->{style} = 'color:purple;';
print $p->text ();

