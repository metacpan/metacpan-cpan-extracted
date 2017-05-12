#!perl
use strict;
use warnings;
use Test::More tests => 27;

BEGIN {
  use_ok('Math::Symbolic');
  use_ok('Math::SymbolicX::ParserExtensionFactory');
}
use Math::SymbolicX::ParserExtensionFactory 
  fun_func => sub {
    Test::More::ok(1, "in fun_func");
    return Math::Symbolic::Constant->new(2);
  };

SCOPE: {
  my $parser = Math::Symbolic::Parser->new(
    implementation => 'Yapp'
  );

  Math::SymbolicX::ParserExtensionFactory->add_private_functions(
    $parser,
    myfunction => sub {
      ok(1, 'myfunction called at the right time');
      ok($_[0] eq 'myargument*(2-1)');
      return Math::Symbolic::Constant->new(5);
    },
  );

  pass('Still alive after modifying the parser.');

  my $parsed = $parser->parse('1 + myfunction(myargument*(2-1)) * myfunction(myargument*(2-1)) + fun_func(1)');

  ok(ref $parsed eq 'Math::Symbolic::Operator', 'parsed alright');

  ok($parsed->value()==28, 'works alright');
}

SCOPE: {
  my $parser = Math::Symbolic::Parser->new(
    implementation => 'Yapp'
  );

  my $parsed;
  eval {$parsed = $parser->parse('1 + myfunction(myargument*(2-1)) * myfunction(myargument*(2-1)) + fun_func(1)'); };

  ok(!defined($parsed) || $@, 'Parse failed as expected');
}


SCOPE: {
  my $parser = Math::Symbolic::Parser->new(
    implementation => 'RecDescent'
  );

  Math::SymbolicX::ParserExtensionFactory->add_private_functions(
    $parser,
    myfunction2 => sub {
      ok(1, 'myfunction2 called at the right time');
      ok($_[0] eq 'myargument*(2-1)');
      return Math::Symbolic::Constant->new(6);
    },
  );

  pass('Still alive after modifying the parser.');

  my $parsed = $parser->parse('1 + myfunction2(myargument*(2-1)) * myfunction2(myargument*(2-1)) + fun_func(1)');

  ok(ref $parsed eq 'Math::Symbolic::Operator', 'parsed alright');

  ok($parsed->value()==39, 'works alright');
}

SCOPE: {
  my $parser = Math::Symbolic::Parser->new(
    implementation => 'RecDescent'
  );

  my $parsed;
  eval {$parsed = $parser->parse('1 + myfunction2(myargument*(2-1)) * myfunction2(myargument*(2-1)) + fun_func(1)'); };

  ok(!defined($parsed) || $@, 'Parse failed as expected');
}


SCOPE: {
  my $parser = Math::Symbolic::Parser->new(
    implementation => 'RecDescent'
  );

  my $parsed;
  eval {$parsed = $parser->parse('1 + myfunction(myargument*(2-1)) * myfunction(myargument*(2-1)) + fun_func(1)'); };

  ok(!defined($parsed) || $@, 'Parse failed as expected');
}


SCOPE: {
  my $parser = Math::Symbolic::Parser->new(
    implementation => 'Yapp'
  );

  my $parsed;
  eval {$parsed = $parser->parse('1 + myfunction2(myargument*(2-1)) * myfunction2(myargument*(2-1)) + fun_func(1)'); };

  ok(!defined($parsed) || $@, 'Parse failed as expected');
}


