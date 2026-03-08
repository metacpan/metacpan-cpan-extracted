package IO::K8s::Api::Storage::V1::CSINodeSpec;
# ABSTRACT: CSINodeSpec holds information about the specification of all CSI drivers installed on a node
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s drivers => ['Storage::V1::CSINodeDriver'], 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Storage::V1::CSINodeSpec - CSINodeSpec holds information about the specification of all CSI drivers installed on a node

=head1 VERSION

version 1.006

=head2 drivers

drivers is a list of information of all CSI Drivers existing on a node. If all drivers in the list are uninstalled, this can become empty.

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
