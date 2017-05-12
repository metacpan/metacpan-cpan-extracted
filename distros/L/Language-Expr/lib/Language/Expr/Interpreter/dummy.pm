package Language::Expr::Interpreter::dummy;

our $DATE = '2016-07-03'; # DATE
our $VERSION = '0.29'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;
use parent 'Language::Expr::Interpreter::Base';
with 'Language::Expr::InterpreterRole';

sub rule_pair_simple { }
sub rule_pair_string { }
sub rule_or_xor { }
sub rule_ternary { }
sub rule_and { }
sub rule_bit_or_xor { }
sub rule_bit_and { }
sub rule_comparison3 { }
sub rule_comparison { }
sub rule_bit_shift { }
sub rule_add { }
sub rule_mult { }
sub rule_unary { }
sub rule_power { }
sub rule_subscripting_var { }
sub rule_subscripting_expr { }
sub rule_array { }
sub rule_hash { }
sub rule_undef { }
sub rule_squotestr { }
sub rule_dquotestr { }
sub rule_bool { }
sub rule_num { }
sub rule_var { }
sub rule_func { }
sub rule_func_map { }
sub rule_func_grep { }
sub rule_func_usort { }
sub rule_parenthesis { }
sub expr_preprocess { }
sub expr_postprocess { }

1;
# ABSTRACT: Dummy interpreter for Language::Expr (used for testing)

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Expr::Interpreter::dummy - Dummy interpreter for Language::Expr (used for testing)

=head1 VERSION

This document describes version 0.29 of Language::Expr::Interpreter::dummy (from Perl distribution Language-Expr), released on 2016-07-03.

=head1 DESCRIPTION

This interpreter does nothing. It is used only for testing the parser.

=for Pod::Coverage ^(rule|expr)_.+

=head1 ATTRIBUTES

=head1 METHODS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Language-Expr>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Language-Expr>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Language-Expr>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
