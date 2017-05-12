#!/usr/bin/env perl

# An "almost-RPN-ish" calculator ...
use feature 'say';
use Lowu;

if (@ARGV) {
  say calc(join ' ', @ARGV)->join(" ");
  exit 0
}

[
  qq[Hi! I'm a RPN-ish calculator.],
  qq[ - The stack only persists for a single expression.],
  qq[ - Operations reduce the stack recursively.],
  qq[ - Commands (anywhere in an expression):],
  qq[   'q' quits],
  qq[   'p' prints the current stack],
  qq[   'pFORMAT applies FORMAT to each stack element via (s)printf],
]->map(sub { say $_ });

STDOUT->autoflush(1);

while (1) {
  print "Enter an expression:\n", "> ";
  my $expr = <STDIN>;
  say "result: " . calc($expr)->join(" ")
}

sub calc {
  my $stack = [];
  for my $item (split ' ', shift) {
    if ($item eq 'q' || $item eq 'quit') {
      exit 0
    }

    if ($item eq 'p' || $item eq 'print') {
      say "stack: " . $stack->join(" ");
      next
    }

    if (my ($format) = $item =~ /\Ap(?:rint)?(\S+)\Z/) {
      $stack->map(sub { say sprintf $format, $_ });
      next
    }

    if ($item =~ /\A[0-9]+\Z/) {
      $stack->push($item);
      next
    }

    next unless $stack->has_any;
    unless ($stack->count > 1) {
      warn "Not enough stack elements to perform operations\n";
      next
    }

    if ($item eq '+') {
      $stack = array( $stack->reduce(sub { shift() + shift() }) );
      next
    }
    if ($item eq '-') {
      $stack = array( $stack->reduce(sub { shift() - shift() }) );
      next
    }
    if ($item eq '*') {
      $stack = array( $stack->reduce(sub { shift() * shift() }) );
      next
    }
    if ($item eq '/') {
      $stack = array( $stack->reduce(sub { shift() / shift() }) );
      next
    }
    if ($item eq '^' || $item eq '**') {
      $stack = array( $stack->reduce(sub { shift() ** shift() }) );
      next
    }

    warn "Unknown token: $item\n"
  }

  $stack
}
