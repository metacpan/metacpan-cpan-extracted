#!perl
use strict;
use warnings;
use lib 'lib';
use Devel::ebug;
use Test::More;

my @tricky = ('two words', 'a$b', q{it's "quoted"}, '*', '');

plan tests => 16;

sub args_of {
  my($ebug) = @_;
  $ebug->next;
  $ebug->next;
  my @args;
  foreach my $i (0 .. $ebug->eval('$count') - 1) {
    push @args, scalar $ebug->eval("\$args[$i]");
  }
  return \@args;
}

{
  my $ebug = Devel::ebug->new;
  $ebug->program('corpus/args.pl');
  $ebug->args([@tricky]);
  $ebug->load;
  is($ebug->eval('scalar @ARGV'), scalar @tricky, 'each argument arrives as one element of @ARGV');
  is_deeply(args_of($ebug), \@tricky, 'and each is untouched by the shell');

  $ebug->undo;
  is($ebug->line, 7, 'undo restarts the program');
  is($ebug->eval('scalar @ARGV'), scalar @tricky, 'with the same number of arguments');
  is($ebug->eval('$args[0]'), 'two words', 'and the same arguments');
}

{
  my $ebug = Devel::ebug->new;
  $ebug->program('corpus/args.pl 3 "four five"');
  $ebug->load;
  is_deeply(args_of($ebug), [ 3, 'four five' ], 'without args, program still goes through the shell');
}

{
  my $ebug = Devel::ebug->new;
  $ebug->program('corpus/args.pl');
  $ebug->args([]);
  $ebug->load;
  is($ebug->eval('scalar @ARGV'), 0, 'an empty args list passes no arguments');
}

{
  my $ebug = Devel::ebug->new;
  $ebug->backend("$^X bin/ebug_backend_perl");
  $ebug->program('corpus/args.pl');
  $ebug->args(['two words']);
  $ebug->load;
  is_deeply(args_of($ebug), [ 'two words' ], 'args work with a custom backend');
}

SKIP: {
  eval { require Test::Expect; require Expect::Simple };
  skip 'This test requires Test::Expect and Expect::Simple', 8 if $@;
  Test::Expect->import;

  expect_run(
    command => "PERL_RL=\"o=0\" $^X bin/ebug --backend \"$^X bin/ebug_backend_perl\" corpus/args.pl 'two words' 'a\$b'",
    prompt  => 'ebug: ',
    quit    => 'q',
  );
  expect_like(qr/Welcome to Devel::ebug/, 'the console starts');
  expect_send('e scalar @ARGV', 'ask for the argument count');
  expect_like(qr/\A2(?:\n|\z)/, 'the console passes each argument separately');
  expect_send('e $ARGV[0]', 'ask for the first argument');
  expect_like(qr/\Atwo words(?:\n|\z)/, 'keeping spaces');
  expect_send('e $ARGV[1]', 'ask for the second argument');
  expect_like(qr/\Aa\$b(?:\n|\z)/, 'and shell metacharacters');
}
