package IO::K8s::Api::Resource::V1beta2::DeviceTaintRuleSpec;
# ABSTRACT: DeviceTaintRuleSpec specifies the selector and one taint.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s deviceSelector => 'Resource::V1beta2::DeviceTaintSelector';


k8s taint => 'Resource::V1::DeviceTaint', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta2::DeviceTaintRuleSpec - DeviceTaintRuleSpec specifies the selector and one taint.

=head1 VERSION

version 1.106

=head2 deviceSelector

DeviceSelector defines which device(s) the taint is applied to. All selector criteria must be satisfied for a device to match. The empty selector matches all devices. Without a selector, no devices are matches.

=head2 taint

The taint that gets applied to matching devices.

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
