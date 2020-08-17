#!perl
use strict;
use warnings;
use Test::More;
use Lox;
use Lox::Interpreter;

subtest eval => sub {
  my $i = Lox::Interpreter->new;
  my $value = 'bar';
  Lox::eval($i, qq(var foo = "$value";));
  open my $out_fh, '>>', \(my $output);
  select($out_fh);
  Lox::eval($i, 'print foo;');
  is $output, "$value\n", 'eval prints our value';
};

done_testing;
