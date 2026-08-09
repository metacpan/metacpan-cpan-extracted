package IO::K8s::Api::Resource::V1::DeviceCounterConsumption;
# ABSTRACT: DeviceCounterConsumption defines a set of counters that a device will consume from a CounterSet.
our $VERSION = '1.105';
use IO::K8s::Resource;

k8s counterSet => Str, 'required';


k8s counters => { Str => 1 }, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1::DeviceCounterConsumption - DeviceCounterConsumption defines a set of counters that a device will consume from a CounterSet.

=head1 VERSION

version 1.105

=head2 counterSet

CounterSet is the name of the set from which the counters defined will be consumed.

=head2 counters

Counters defines the counters that will be consumed by the device. The maximum number of counters is 32.

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
