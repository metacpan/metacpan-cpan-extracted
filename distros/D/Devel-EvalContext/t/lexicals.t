# test lexicals being saved and restored
use strict; use warnings;
use Test::More tests => 5;
use Devel::EvalContext;

my $ctx = Devel::EvalContext->new;

{
  our $test1 = 0;
  $ctx->run(q{ $::test1 = 42; });
  is($test1, 42, "code runs in same interpreter");
}

{
  our $test2 = 0;
  $ctx->run(q{ my $a = 123; });
  $ctx->run(q{ $::test2 = $a });
  is($test2, 123, "lexical variables preserved between statements");
}

{
  our $test3 = 0;
  $ctx->run(q{ my $b = 123; });
  $ctx->run(q{ $::test3 = $a + $b });
  is($test3, 246, "lexical variables are added to");
}

{
  our $test4 = 0;
  $ctx->run(q{ my $c = \$a });
  $ctx->run(q{ my $a = 56; });
  $ctx->run(q{ $::test4 = $a });
  is($test4, 56, "new lexical variable shadows old");
  $ctx->run(q{ $::test4 = $$c });
  is($test4, 123, "but original does still exists");
}
