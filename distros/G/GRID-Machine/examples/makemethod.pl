#!/usr/bin/perl -w
use strict;
use GRID::Machine;

my $host = shift || $ENV{GRID_REMOTE_MACHINE};

my $m = GRID::Machine->new(host => $host, uses => [q{List::Util qw{reduce}}]);

$m->makemethod( 'reduce', filter => 'result' );
my $r = $m->reduce(sub { $a > $b ? $a : $b }, (7,6,5,12,1,9));
print "\$r =  $r\n";

my $m2 = GRID::Machine->new(host => $host, uses => [q{List::Util}]);

$m2->makemethod( 'List::Util::reduce' );
$r = $m2->reduce(sub { $a > $b ? $a : $b }, (7,6,5,12,1,9));
die $r->errmsg unless $r->ok;
print "\$r =  ".$r->result."\n";
