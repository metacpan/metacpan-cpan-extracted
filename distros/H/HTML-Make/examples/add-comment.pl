#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make;
my $p = HTML::Make->new ('p', text => 'Help! I need somebody! Help!');
$p->add_comment ('This should be fixed');
print $p->text ();

