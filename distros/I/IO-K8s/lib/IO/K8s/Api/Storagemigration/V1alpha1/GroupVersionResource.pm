package IO::K8s::Api::Storagemigration::V1alpha1::GroupVersionResource;
# ABSTRACT: The names of the group, the version, and the resource.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s group => Str;


k8s resource => Str;


k8s version => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Storagemigration::V1alpha1::GroupVersionResource - The names of the group, the version, and the resource.

=head1 VERSION

version 1.009

=head2 group

The name of the group.

=head2 resource

The name of the resource.

=head2 version

The name of the version.

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
