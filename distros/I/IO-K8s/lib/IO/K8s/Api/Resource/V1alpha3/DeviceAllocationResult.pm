package IO::K8s::Api::Resource::V1alpha3::DeviceAllocationResult;
# ABSTRACT: DeviceAllocationResult is the result of allocating devices.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s config => ['Resource::V1alpha3::DeviceAllocationConfiguration'];


k8s results => ['Resource::V1alpha3::DeviceRequestAllocationResult'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::DeviceAllocationResult - DeviceAllocationResult is the result of allocating devices.

=head1 VERSION

version 1.008

=head2 config

This field is a combination of all the claim and class configuration parameters. Drivers can distinguish between those based on a flag.

This includes configuration parameters for drivers which have no allocated devices in the result because it is up to the drivers which configuration parameters they support. They can silently ignore unknown configuration parameters.

=head2 results

Results lists all allocated devices.

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
