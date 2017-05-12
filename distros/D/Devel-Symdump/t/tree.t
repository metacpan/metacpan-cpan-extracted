#!/usr/bin/perl -w

# tree.t

use Devel::Symdump;

package Coffee;
@ISA = qw(Liquid Black);

package Liquid;
package Black;

package Martini;
@ISA = qw(Liquid);

package Martini::White;
@ISA = qw(Martini);
package Martini::Red;
@ISA = qw(Martini);

print "1..2\n";
my @s = split /\n/, Devel::Symdump->isa_tree;
print @s >= 11 ? "ok 1\n" : "not ok [@s]\n";
@s = split /\n/, Devel::Symdump->inh_tree;
print @s >= 9 ? "ok 2\n" : "not ok [@s]\n";

# The tests are testing with the > operator, because we never know where
# Exporter and Carp (and others) are developing into.
