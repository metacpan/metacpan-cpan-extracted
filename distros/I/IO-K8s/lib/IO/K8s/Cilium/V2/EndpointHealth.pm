package IO::K8s::Cilium::V2::EndpointHealth;
# ABSTRACT: Health is the overall endpoint & subcomponent health.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s bpf           => Str;
k8s connected     => Bool;
k8s overallHealth => Str;
k8s policy        => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::EndpointHealth - Health is the overall endpoint & subcomponent health.

=head1 VERSION

version 1.108

=head2 bpf

bpf

=head2 connected

Is this endpoint reachable

=head2 overallHealth

overall health

=head2 policy

policy

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
