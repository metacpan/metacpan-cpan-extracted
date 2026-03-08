package IO::K8s::Api::Core::V1::PersistentVolumeStatus;
# ABSTRACT: PersistentVolumeStatus is the current status of a persistent volume.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s lastPhaseTransitionTime => Time;


k8s message => Str;


k8s phase => Str;


k8s reason => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PersistentVolumeStatus - PersistentVolumeStatus is the current status of a persistent volume.

=head1 VERSION

version 1.006

=head2 lastPhaseTransitionTime

lastPhaseTransitionTime is the time the phase transitioned from one to another and automatically resets to current time everytime a volume phase transitions.

=head2 message

message is a human-readable message indicating details about why the volume is in this state.

=head2 phase

phase indicates if a volume is available, bound to a claim, or released by a claim. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#phase

=head2 reason

reason is a brief CamelCase string that describes any failure and is meant for machine parsing and tidy display in the CLI.

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
