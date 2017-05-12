package Test::DDT;
use Devel::DumpTrace;
use Test::More tests => 2;
use strict;
use warnings;

# tests a recursion issue in Devel::DumpTrace::dump_scalar
# that should be fixed in v0.15

my $f = { foo => 'bar', abc => 'def' };
ok(Devel::DumpTrace::dump_scalar($f), 
   'dump_scalar runs on reference');



$f->{self} = $f;
ok(Devel::DumpTrace::dump_scalar($f),
   'dump_scalar handles recursive reference without blowing up');


