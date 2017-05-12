#!perl -T

use Test::More tests => 4;

use Launcher::Cascade::Base;

my $A = new Launcher::Cascade::Base -name => 'Launcher A';
my $B = new Launcher::Cascade::Base -name => 'Launcher B';
my $C = new Launcher::Cascade::Base -name => 'Launcher C', -dependencies => [ $A, $B ];

local $" = " - ";

my @dep = $C->dependencies();
is("@dep", 'Launcher A - Launcher B', 'Passing arrayref');

$C->dependencies($A, $B);
@dep = $C->dependencies();
is("@dep", 'Launcher A - Launcher B', 'Passing list');

$C->dependencies([ $A ]);
@dep = $C->dependencies();
is("@dep", 'Launcher A', 'Passing 1-elem arrayref');

$C->dependencies($A);
@dep = $C->dependencies();
is("@dep", 'Launcher A', 'Passing 1-elem list');
