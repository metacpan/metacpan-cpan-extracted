package IO::K8s::Api::Admissionregistration::V1alpha1::ExpressionWarning;
# ABSTRACT: ExpressionWarning is a warning information that targets a specific expression.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s fieldRef => Str, 'required';


k8s warning => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Admissionregistration::V1alpha1::ExpressionWarning - ExpressionWarning is a warning information that targets a specific expression.

=head1 VERSION

version 1.100

=head2 fieldRef

The path to the field that refers the expression. For example, the reference to the expression of the first item of validations is "spec.validations[0].expression"

=head2 warning

The content of type checking information in a human-readable form. Each line of the warning contains the type that the expression is checked against, followed by the type check error from the compiler.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
