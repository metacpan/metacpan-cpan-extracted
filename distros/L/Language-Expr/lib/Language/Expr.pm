package Language::Expr;

our $DATE = '2016-07-03'; # DATE
our $VERSION = '0.29'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub get_compiler {
    my ($self, $name) = @_;
    my $mod = "Language::Expr::Compiler::$name";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;
    $mod->new();
}

sub get_interpreter {
    my ($self, $name) = @_;
    my $mod = "Language::Expr::Interpreter::$name";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;
    $mod->new();
}

1;
# ABSTRACT: Simple minilanguage for use in expression

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Expr - Simple minilanguage for use in expression

=head1 VERSION

This document describes version 0.29 of Language::Expr (from Perl distribution Language-Expr), released on 2016-07-03.

=head1 SYNOPSIS

 use Language::Expr;

 my $le = Language::Expr->new;

 # convert Expr to string Perl code
 say $le->get_compiler('perl')->compile('1 ^^ 2'); => # "(1 xor 2)"

 # convert Expr to JavaScript
 say $le->get_compiler('js')->compile('1 . 2'); # => "'' + 1 + 2"

 # evaluate Expr using the default interpreter
 say $le->get_interpreter('default')->eval('1 + 2'); # => 3

 # enumerate variables
 my $vars = $le->enum_vars('$a*$a + sqr($b)'); # => ['a', 'b']

=head1 DESCRIPTION

Language::Expr defines a simple, Perl-like expression minilanguage. It supports
mathematical and string operators, arrays, hashes, variables, and functions. See
L<Language::Expr::Manual::Syntax> for description of the language syntax.

This distribution consists of the language parser (L<Language::Expr::Parser>),
some interpreters (Language::Expr::Interpreter::*), and some compilers
(Language::Expr::Compiler::*).

=head1 KNOWN BUGS

Due to possible bugs in Perl's RE engine or Regexp::Grammars or my
grammar, some syntax errors will cause further parsing to
fail.

=head1 ATTRIBUTES

=head1 METHODS

=head2 new()

=head2 get_compiler($name) => obj

Get compiler named C<$name>, e.g. C<perl>, C<js>.

=head2 get_interpreter($name) => obj

Get compiler named C<$name>, e.g. C<default>, C<var_enumer>, C<dummy>.

=head1 FAQ

=head2 Why yet another simplistic (restricted, etc) language? Why not just Perl?

When first adding expression support to L<Data::Schema> (now L<Data::Sah>), I
want a language that is simple enough so I can easily convert it to Perl, PHP,
JavaScript, and others. I do not need a fully-fledged programming language. In
fact, Expr is not even Turing-complete, it does not support assignment or loops.
Nor does it allow function definition (though it allows anonymous function in
grep/map/usort). Instead, I just need some basic stuffs like
mathematical/string/logical operators, arrays, hashes, functions,
map/grep/usort. This language will mostly be used inside templates and schemas.

=head2 Why don't you use Language::Farnsworth, or Math::Expression, or Math::Expression::Evaluator, or $FOO?

I need several compilers and interpreters (some even with different semantics),
so it's easier to start with a simple parser of my own. And of course there is
personal preference of language syntax.

=head2 What is the difference between a compiler and interpreter?

An interpreter evaluates expression as it is being parsed, while a compiler
generates a complete Perl (or whatever) code first. Thus, if you $le->eval()
repeatedly using the interpreter mode (setting $le->interpreted(1)), you will
repeatedly parse the expression each time. This can be one or more orders of
magnitude slower compared to compiling into Perl once and then directly
executing the Perl code repeatedly.

Note that if you use $le->eval() using the default compiler mode, you do not
reap the benefits of compilation because the expression will be compiled each
time you call $le->eval(). To save the compilation result, use $le->compile() or
$le->perl() and compile the Perl code yourself using Perl's eval().

=head2 I want different syntax for (variables, foo operator, etc)!

Create your own language :-) Fork this distribution and start
modifying the Language::Expr::Parser module.

=head2 How to show details of errors in expression?

This is a TODO item.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Language-Expr>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Language-Expr>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Language-Expr>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Syntax reference: L<Language::Expr::Manual::Syntax>

Modules that are using Language::Expr: L<Data::Sah>, L<Data::Template::Expr>
(not yet released).

Other related modules: L<Math::Expression>, L<Math::Expression::Evaluator>,
L<Language::Farnsworth>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
