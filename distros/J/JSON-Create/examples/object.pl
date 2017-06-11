#!/usr/bin/env perl
use warnings;
use strict;
package Ba::Bi::Bu::Be::Bo;
sub new { my $lion = 'lion'; return bless \$lion; }
1;
package main;
use JSON::Create 'create_json';
my $babibubebo = Ba::Bi::Bu::Be::Bo->new ();
print "$babibubebo\n";
my $stuff = { babibubebo => $babibubebo };
print create_json ($stuff), "\n";
