package IO::K8s::Api::Core::V1::AzureFileVolumeSource;
# ABSTRACT: AzureFile represents an Azure File Service mount on the host and bind mount to the pod.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s readOnly => Bool;


k8s secretName => Str, 'required';


k8s shareName => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::AzureFileVolumeSource - AzureFile represents an Azure File Service mount on the host and bind mount to the pod.

=head1 VERSION

version 1.100

=head2 readOnly

readOnly defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.

=head2 secretName

secretName is the  name of secret that contains Azure Storage Account Name and Key

=head2 shareName

shareName is the azure share Name

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
