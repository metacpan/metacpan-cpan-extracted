package IO::K8s::Api::Admissionregistration::V1beta1::TypeChecking;
# ABSTRACT: TypeChecking contains results of type checking the expressions in the ValidatingAdmissionPolicy
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s expressionWarnings => ['Admissionregistration::V1beta1::ExpressionWarning'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Admissionregistration::V1beta1::TypeChecking - TypeChecking contains results of type checking the expressions in the ValidatingAdmissionPolicy

=head1 VERSION

version 1.008

=head2 expressionWarnings

The type checking warnings for each expression.

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
