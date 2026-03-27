package IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerCondition;
# ABSTRACT: HorizontalPodAutoscalerCondition describes the state of a HorizontalPodAutoscaler at a certain point.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s lastTransitionTime => Time;


k8s message => Str;


k8s reason => Str;


k8s status => Str, 'required';


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerCondition - HorizontalPodAutoscalerCondition describes the state of a HorizontalPodAutoscaler at a certain point.

=head1 VERSION

version 1.100

=head2 lastTransitionTime

lastTransitionTime is the last time the condition transitioned from one status to another

=head2 message

message is a human-readable explanation containing details about the transition

=head2 reason

reason is the reason for the condition's last transition.

=head2 status

status is the status of the condition (True, False, Unknown)

=head2 type

type describes the current condition

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
