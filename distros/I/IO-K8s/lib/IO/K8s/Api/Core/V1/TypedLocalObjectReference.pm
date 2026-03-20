package IO::K8s::Api::Core::V1::TypedLocalObjectReference;
# ABSTRACT: TypedLocalObjectReference contains enough information to let you locate the typed referenced object inside the same namespace.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s apiGroup => Str;


k8s kind => Str, 'required';


k8s name => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::TypedLocalObjectReference - TypedLocalObjectReference contains enough information to let you locate the typed referenced object inside the same namespace.

=head1 VERSION

version 1.009

=head2 apiGroup

APIGroup is the group for the resource being referenced. If APIGroup is not specified, the specified Kind must be in the core API group. For any other third-party types, APIGroup is required.

=head2 kind

Kind is the type of resource being referenced

=head2 name

Name is the name of resource being referenced

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
