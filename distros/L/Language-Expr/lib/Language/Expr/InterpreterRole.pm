package Language::Expr::InterpreterRole;

our $DATE = '2016-07-03'; # DATE
our $VERSION = '0.29'; # VERSION

use 5.010;
use strict;
use warnings;

use Role::Tiny;
use Role::Tiny::With;

with 'Language::Expr::EvaluatorRole';
requires 'eval';

1;
# ABSTRACT: Role for Language::Expr::Interpreter::*

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Expr::InterpreterRole - Role for Language::Expr::Interpreter::*

=head1 VERSION

This document describes version 0.29 of Language::Expr::InterpreterRole (from Perl distribution Language-Expr), released on 2016-07-03.

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
