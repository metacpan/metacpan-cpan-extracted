package IO::K8s::Api::Core::V1::ScopedResourceSelectorRequirement;
# ABSTRACT: A scoped-resource selector requirement is a selector that contains values, a scope name, and an operator that relates the scope name and values.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s operator => Str, 'required';


k8s scopeName => Str, 'required';


k8s values => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ScopedResourceSelectorRequirement - A scoped-resource selector requirement is a selector that contains values, a scope name, and an operator that relates the scope name and values.

=head1 VERSION

version 1.100

=head2 operator

Represents a scope's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist.

=head2 scopeName

The name of the scope that the selector applies to.

=head2 values

An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.

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
