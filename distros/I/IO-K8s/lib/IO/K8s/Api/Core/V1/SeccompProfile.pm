package IO::K8s::Api::Core::V1::SeccompProfile;
# ABSTRACT: SeccompProfile defines a pod/container's seccomp profile settings. Only one profile source may be set.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s localhostProfile => Str;


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::SeccompProfile - SeccompProfile defines a pod/container's seccomp profile settings. Only one profile source may be set.

=head1 VERSION

version 1.100

=head2 localhostProfile

localhostProfile indicates a profile defined in a file on the node should be used. The profile must be preconfigured on the node to work. Must be a descending path, relative to the kubelet's configured seccomp profile location. Must be set if type is "Localhost". Must NOT be set for any other type.

=head2 type

type indicates which kind of seccomp profile will be applied. Valid options are:

Localhost - a profile defined in a file on the node should be used. RuntimeDefault - the container runtime default profile should be used. Unconfined - no profile should be applied.

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
