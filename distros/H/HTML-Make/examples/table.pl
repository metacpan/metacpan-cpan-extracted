#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use HTML::Make;
my $table = HTML::Make->new ('table');
my $row = $table->push ('tr');
my $cell = $row->push ('td', text => 'Cell');
print $table->text ();


