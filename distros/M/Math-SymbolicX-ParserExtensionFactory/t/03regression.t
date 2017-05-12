#!perl
use strict;
use warnings;
use Test::More tests => 12;

use_ok('Math::Symbolic');
use_ok('Math::SymbolicX::ParserExtensionFactory');
#$Math::Symbolic::Parser::DEBUG = 1;
use Math::Symbolic qw/parse_from_string/;


ok(1, 'Still alive after modifying the parser.');


{
  my $parsed1 = parse_from_string('sin(pi/3*(2+log(2,1.3)))');

  ok(ref $parsed1 eq 'Math::Symbolic::Operator', 'parsed alright');

  my $parser = Math::Symbolic::Parser->new(implementation => 'Yapp');
  isa_ok($parser, 'Math::Symbolic::Parser::Yapp');

  my $parsed2 = $parser->parse("sin(pi/3*(2+log(2,1.3)))");
  isa_ok($parsed2, 'Math::Symbolic::Operator');
}

Math::SymbolicX::ParserExtensionFactory->import(
  myfunction => sub {Math::Symbolic::Constant->one()},
);

{
  my $parsed1 = parse_from_string('sin(pi/3*(2+log(2,1.3)))');

  ok(ref $parsed1 eq 'Math::Symbolic::Operator', 'parsed alright');

  my $parser = Math::Symbolic::Parser->new(implementation => 'Yapp');
  isa_ok($parser, 'Math::Symbolic::Parser::Yapp');

  my $parsed2 = $parser->parse("sin(pi/3*(2+log(2,1.3)))");
  isa_ok($parsed2, 'Math::Symbolic::Operator');
}

{
  my $parsed1 = parse_from_string('sin(pi/3*(2+log(2,1.3)))+myfunction()');

  ok(ref $parsed1 eq 'Math::Symbolic::Operator', 'parsed alright');

  my $parser = Math::Symbolic::Parser->new(implementation => 'Yapp');
  isa_ok($parser, 'Math::Symbolic::Parser::Yapp');

  my $parsed2 = $parser->parse("sin(pi/3*(2+log(2,1.3)))+myfunction()");
  isa_ok($parsed2, 'Math::Symbolic::Operator');
}

