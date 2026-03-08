package IO::K8s::Api::Core::V1::LinuxContainerUser;
# ABSTRACT: LinuxContainerUser represents user identity information in Linux containers
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s gid => Int, 'required';


k8s supplementalGroups => [Int];


k8s uid => Int, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::LinuxContainerUser - LinuxContainerUser represents user identity information in Linux containers

=head1 VERSION

version 1.006

=head2 gid

GID is the primary gid initially attached to the first process in the container

=head2 supplementalGroups

SupplementalGroups are the supplemental groups initially attached to the first process in the container

=head2 uid

UID is the primary uid initially attached to the first process in the container

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
