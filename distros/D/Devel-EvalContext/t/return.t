# test run's return value and exceptions
use strict; use warnings;
use Test::More tests => 3;
use Devel::EvalContext;

my $ctx = Devel::EvalContext->new;

{
  my ($err, $ret) = eval { $ctx->run(q{ return 123 }) };
  ok(($@ eq '' and !defined($err) and $ret == 123), "returning values");
}

{
  my ($err, $ret) = eval { $ctx->run(q{ die "user error" }) };
  ok(($@ eq '' and $err =~ "user error"), "user error");
}

{
  my ($err, $ret) = eval { $ctx->run(q{ BEGIN { die "compile error" } }) };
  ok(($@ =~ 'compile error'), "compile error");
}
