package Lox;
use strict;
use warnings;
use Lox::AstPrinter;
use Lox::Interpreter;
use Lox::Parser;
use Lox::Resolver;
use Lox::Scanner;
use Lox::TokenType;
our $VERSION = 0.02;

my $had_error = undef;

sub run_file {
  my ($path, $debug_mode) = @_;
  open my $fh, '<', $path or die "Error opening $path: $!";
  my $text = do { local $/; <$fh> };
  my $interpreter = Lox::Interpreter->new;
  Lox::eval($interpreter, $text, $debug_mode);
  if ($had_error) {
    exit 65;
  }
}

sub run_prompt {
  my ($debug_mode) = @_;
  print "Welcome to Perl-Lox version $VERSION\n> ";
  my $interpreter = Lox::Interpreter->new;
  while (my $line = <>) {
    Lox::eval($interpreter, $line, $debug_mode);
    undef $had_error;
    print "> ";
  }
}

sub eval {
  my ($interpreter, $source, $debug_mode) = @_;

  my $tokens = scan($source, $debug_mode);
  return if $had_error;

  my $stmts = parse($tokens, $debug_mode);
  return if $had_error;

  Lox::Resolver->new($interpreter)->run($stmts);
  return if $had_error;

  $interpreter->interpret($stmts);
}

sub scan {
  my ($source, $debug_mode) = @_;
  my $scanner = Lox::Scanner->new({source => $source});
  eval { $scanner->scan_tokens };
  if ($@) {
    die "Unexpected error: $@";
  }
  $scanner->print if $debug_mode;
  return $scanner->tokens;
}

sub parse {
  my ($tokens, $debug_mode) = @_;
  my $parser = Lox::Parser->new({tokens => $tokens});
  my $stmts = $parser->parse;
  if ($parser->errors->@*) {
    error(@$_) for ($parser->{errors}->@*);
  }
  print Lox::AstPrinter->new->print_tree($stmts), "\n" if $debug_mode;
  return $stmts;
}

sub runtime_error {
  my ($token, $message) = @_;
  report($token->{line}, "at '$token->{lexeme}'", $message);
  exit 65;
}

sub error {
  my ($token, $message) = @_;
  $had_error = 1;
  report($token->{line}, "at '$token->{lexeme}'", $message);
}

sub report {
  my ($line, $where, $message) = @_;
  printf "[Line %s] Error %s: %s.\n", $line, $where, $message;
}

1;
__END__
=head1 NAME

Lox - A Perl implementation of the Lox programming language

=head1 DESCRIPTION

A Perl translation of the Java Lox interpreter from
L<Crafting Interpreters|https://craftinginterpreters.com/>.

=head1 INSTALL

As long as you have Perl 5.24.0 or greater, you should be able to run C<plox>
from the root project directory.

If you'd rather build and install it:

  $ perl Makefile.PL
  $ make
  $ make test
  $ make install

=head1 SYNOPSIS

If you have built and installed C<plox>:

  $ plox
  Welcome to Perl-Lox version 0.02
  >

  $ plox hello.lox
  Hello, World!

Otherwise from the root project directory:

  $ perl -Ilib bin/plox
  Welcome to Perl-Lox version 0.02
  >

  $ perl -Ilib bin/plox hello.lox
  Hello, World!


Pass the C<--debug> or C<-d> option to C<plox> to print the tokens it scanned
and the parse tree.

=head1 TESTING

The test suite includes 238 test files from the Crafting Interpreters
L<repo|https://github.com/munificent/craftinginterpreters>.

  $ prove -l t/*

=head1 EXTENSIONS

Perl-Lox has these capabilities from the "challenges" sections of the book:

=over 2

=item * Anonymous functions C<fun () { ... }>

=item * Break statements in loops

=item * Multi-line comments C</* ... */>

=item * New Exceptions:

=over 2

=item * Evaluating an uninitialized variable

=back

=back

=head1 DIFFERENCES

Differences from the canonical "jlox" implementation:

=over 2

=item * repl is stateful

=item * signed zero is unsupported

=item * methods are equivalent

Prints "true" in plox and "false" in jlox:

  class Foo  { bar () { } } print Foo().bar == Foo().bar;

=back

=head1 AUTHOR

Copyright 2020 David Farrell

=head1 LICENSE

See F<LICENSE> file.

=cut
