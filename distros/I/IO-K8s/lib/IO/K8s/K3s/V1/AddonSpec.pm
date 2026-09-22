package IO::K8s::K3s::V1::AddonSpec;
# ABSTRACT: AddonSpec
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s checksum => Str;
k8s source   => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::AddonSpec - AddonSpec

=head1 VERSION

version 1.108

=head2 checksum

Checksum is the SHA256 checksum of the most recently successfully applied manifest file.

=head2 source

Source is the Path on disk to the manifest file that this Addon tracks.

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
