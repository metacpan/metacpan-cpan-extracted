#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'MarpaX::Languages::ECMAScript::AST' ) || print "Bail out!\n";
}

my %asi = (
    "{ 1 2 } 3" => undef,
    "{ 1
2 } 3" => "{ 1
;2 ;} 3;",
    "for (a; b
)" => undef,
    "return
a + b" => "return;
a + b;",
    "a = b
++c" => "a = b;
++c;",
    "if (a > b)
else c = d" => undef,
    "a = b + c
(d + e).print()" => "a = b + c
(d + e).print()"
);

my $ecmaAst = MarpaX::Languages::ECMAScript::AST->new();
foreach (keys %asi) {
    my $ecmaSourceCode = $_;
    my $value;
    eval {$value = $ecmaAst->parse($ecmaSourceCode)};
    my $EventualFailureString = $@;
    my $status = defined($asi{$_}) ? defined($value) : ! defined($value);
    my $statusString = defined($value) ? 'defined' : '<undef>';
    ok($status, $statusString);
    if (! $status) {
      print STDERR "\n********************************\nFailed test was with:--->\"$ecmaSourceCode\"<---.\n\nEventual \$\@ is:\n\"$EventualFailureString\"\n********************************\n";
    }
}

done_testing(1 + scalar(keys %asi));
