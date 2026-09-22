package IO::K8s::Api::Storage::V1::StorageHealthCondition;
# ABSTRACT: StorageHealthCondition represents an adverse health condition reported by a CSI driver for its storage backend on a node.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accessMode => Str;


k8s lastTransitionTime => Time;


k8s message => Str;


k8s reason => Str, 'required';


k8s status => Str, 'required';


k8s volumeMode => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Storage::V1::StorageHealthCondition - StorageHealthCondition represents an adverse health condition reported by a CSI driver for its storage backend on a node.

=head1 VERSION

version 1.108

=head2 accessMode

accessMode is the access mode affected. Nil means all access modes are affected.

=head2 lastTransitionTime

lastTransitionTime is when this condition first appeared at its current state.

=head2 message

message is a human-readable description. Maximum permitted length of a message is 1024 characters.

=head2 reason

reason is a brief CamelCase machine-parseable reason. Maximum permitted length of a reason is 256 characters.

=head2 status

status is the health status category. One of "StorageUnreachable", "StorageDegraded".

=head2 volumeMode

volumeMode is the volume mode affected. Nil means both are affected.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
