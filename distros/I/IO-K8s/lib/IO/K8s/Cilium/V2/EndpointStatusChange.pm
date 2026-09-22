package IO::K8s::Cilium::V2::EndpointStatusChange;
# ABSTRACT: EndpointStatusChange Indication of a change of status swagger:model EndpointStatusChange
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s code      => Str;
k8s message   => Str;
k8s state     => Str;
k8s timestamp => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::EndpointStatusChange - EndpointStatusChange Indication of a change of status swagger:model EndpointStatusChange

=head1 VERSION

version 1.108

=head2 code

Code indicate type of status change
Enum: ["ok","failed"]

=head2 message

Status message

=head2 state

state

=head2 timestamp

Timestamp when status change occurred

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
