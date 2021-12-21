use strict;
use warnings;
use Test::More;
BEGIN { require './t/common.pl'; }

use Inline;
eval { Inline->bind(C => <<'END', structs => 1, force_build => 1, clean_after_build => 0) };
struct Foo {
   int src;
   struct Foo *next;
};
END
is $@, '', 'compiled without error';

eval {
  my $class = 'Inline::Struct::Foo';
  my $aaa = $class->new;
  isa_ok $aaa, $class, 'aaa';
  my $bbb = $class->new;
  isa_ok $bbb, $class, 'bbb';

  $aaa->src(1);
  is $aaa->src, 1, 'set ok';
  $bbb->src(2);
  is $bbb->src, 2, 'set ok';

  $aaa->next($bbb);
  my $next = $aaa->next;
  isa_ok $next, $class, 'successful lookup of next as obj';
  is $next->src, 2, 'next works as obj';
};
is $@, '', 'executed without error';

done_testing;
