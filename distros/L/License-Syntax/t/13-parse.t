#!perl -T

use strict;
use warnings;
use Test::More tests => 8;
use Data::Dumper;
use License::Syntax;
my $o = new License::Syntax 't/tmpmap.sqlite;lic_map(old_name,new_name)';
#1
ok(defined($o), "sqlite new");

for my $t (
           [5,5," gPL V2 only ; (BSD 4-Clause <<Ex(UCB) & (foobar | dual) ); 
	      PERMISSIVE_OSI_COMPLIANT (odd \n& strange ; Syntax)"],
           [11,5,'GPLv2 & Apache 1.1; LGPLv2.1 | BSD4c<<ex(UCB); Any Noncommercial']
          )
  {
    for my $disambiguate (0..1)
      {
	my $tree = $o->tokenize($t->[2], $disambiguate);
	#2..3, 4..5
	warn Dumper $t->[2], $tree;
	ok(scalar(@$tree) == $t->[$disambiguate], "tokenize '$t->[2]'");
	# warn Dumper $tree;
	my $canon = $o->format_tokens($tree);
	warn "\ncanonical form (disambiguate=$disambiguate):\n\t$canon\n";
      }
  }
#6
ok($o->{diagnostics}[0] =~ m{'foobar'}, 'foobar in diagnostics');
#7
ok($o->{diagnostics}[1] =~ m{'dual'}, 'dual in diagnostics');
while (($o->{diagnostics}[0]||'') =~ m{'(dual|foobar)'}i)
  {
    shift @{$o->{diagnostics}};
  }
my $diag = join("\n", @{$o->{diagnostics}});

#8
warn Dumper $diag if length $diag;
ok($diag eq '', 'no parse errors');

