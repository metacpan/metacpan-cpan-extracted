package IO::K8s::Api::Resource::V1alpha3::CELDeviceSelector;
# ABSTRACT: CELDeviceSelector contains a CEL expression for selecting a device.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s expression => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::CELDeviceSelector - CELDeviceSelector contains a CEL expression for selecting a device.

=head1 VERSION

version 1.006

=head2 expression

Expression is a CEL expression which evaluates a single device. It must evaluate to true when the device under consideration satisfies the desired criteria, and false when it does not. Any other result is an error and causes allocation of devices to abort.

The expression's input is an object named "device", which carries the following properties:

=over 4

=item * driver (string): the name of the driver which defines this device.

=item * attributes (map[string]object): the device's attributes, grouped by prefix (e.g. device.attributes["dra.example.com"] evaluates to an object with all of the attributes which were prefixed by "dra.example.com".

=item * capacity (map[string]object): the device's capacities, grouped by prefix.

=back

Example: Consider a device with driver="dra.example.com", which exposes two attributes named "model" and "ext.example.com/family" and which exposes one capacity named "modules". This input to this expression would have the following fields:

    device.driver
    device.attributes["dra.example.com"].model
    device.attributes["ext.example.com"].family
    device.capacity["dra.example.com"].modules

The device.driver field can be used to check for a specific driver, either as a high-level precondition (i.e. you only want to consider devices from this driver) or as part of a multi-clause expression that is meant to consider devices from different drivers.

The value type of each attribute is defined by the device definition, and users who write these expressions must consult the documentation for their specific drivers. The value type of each capacity is Quantity.

If an unknown prefix is used as a lookup in either device.attributes or device.capacity, an empty map will be returned. Any reference to an unknown field will cause an evaluation error and allocation to abort.

A robust expression should check for the existence of attributes before referencing them.

For ease of use, the cel.bind() function is enabled, and can be used to simplify expressions that access multiple attributes with the same domain. For example:

    cel.bind(dra, device.attributes["dra.example.com"], dra.someBool && dra.anotherBool)

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
