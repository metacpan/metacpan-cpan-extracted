package Language::MinCaml;
use strict;
our $VERSION = '0.01';

use 5.8.1;
use Language::MinCaml::Code;
use Language::MinCaml::Lexer;
use Language::MinCaml::Parser;
use Language::MinCaml::Type;
use Language::MinCaml::TypeInferrer;
use Language::MinCaml::Evaluator;

sub _interpret {
    my($class, $code) = @_;

    my $lexer = Language::MinCaml::Lexer->new($code);

    my $parser = Language::MinCaml::Parser->new;
    my $root_node = $parser->parse($lexer);

    my $inferrer = Language::MinCaml::TypeInferrer->new;
    $inferrer->infer($root_node,
                     (print_int => Type_Fun([Type_Int()], Type_Unit()),
                      print_float => Type_Fun([Type_Float()], Type_Unit())));

    my $evaluator = Language::MinCaml::Evaluator->new;
    $evaluator->evaluate($root_node,
                         (print_int => sub { print shift; return; },
                          print_float => sub { print shift; return; }));
}

sub interpret_string {
    my($class, $string) = @_;
    $class->_interpret(Language::MinCaml::Code->from_string($string));
}

sub interpret_file {
    my($class, $file_path) = @_;
    $class->_interpret(Language::MinCaml::Code->from_file($file_path));
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Language::MinCaml - MinCaml Interpreter

=head1 SYNOPSIS

  use Language::MinCaml;

  # interpret a string
  Language::MinCaml->interpret_string(<<EOC);
  let rec gcd m n =
    if m = 0 then n else
    if m <= n then gcd m (n - m) else
    gcd n (m - n) in
  print_int (gcd 100 125)
  EOC

  # or, interpret a source file
  Language::MinCaml->interpret_file('/path/to/source.ml');

=head1 DESCRIPTION

Language::MinCaml is an interpreter of MinCaml which is a subset of programming language ML.

MinCaml was originally defined by Eijiro Sumii, and he implemented the MinCaml compiler with OCaml for educational purposes.

=head2 FUNCTIONS

=over 2

=item interpret_string($string)

Interpret a string representing a MinCaml code.

=item interpret_file($file_path)

Interpret a MinCaml code in a file pointed to by $file_path.

=back

=head1 TODO

Support skipping comment lines '(* .. *)'.

Support other built-in functions (Now only print_int and print_float).

Improve error messages.

=head1 AUTHOR

Yu Nejigane E<lt>nejigane@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

This module is dependent on Parse::Yapp module for parsing.
L<Parse::Yapp>

L<http://min-caml.sourceforge.net/index-e.html>

=cut
