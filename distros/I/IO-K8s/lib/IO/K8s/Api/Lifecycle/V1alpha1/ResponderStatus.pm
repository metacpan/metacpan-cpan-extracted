package IO::K8s::Api::Lifecycle::V1alpha1::ResponderStatus;
# ABSTRACT: ResponderStatus represents the last observed status of the eviction process of the responder. It should be only updated by the designated responder whose name is .name field.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s completionTime => Time;


k8s expectedCompletionTime => Time;


k8s heartbeatTime => Time;


k8s message => Str;


k8s name => Str, 'required';


k8s startTime => Time;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Lifecycle::V1alpha1::ResponderStatus - ResponderStatus represents the last observed status of the eviction process of the responder. It should be only updated by the designated responder whose name is .name field.

=head1 VERSION

version 1.108

=head2 completionTime

completionTime tracks the time at which the Responder stopped processing the eviction request. Completion means that the responders has either fully or partially completed the eviction process, which may have resulted in target eviction (e.g. pod termination). It should reflect the present time when set. This field becomes immutable once set.

=head2 expectedCompletionTime

expectedCompletionTime is the time at which the eviction process step is expected to end for the responder. The time cannot be set to the past. May be omitted if no estimate can be made.

=head2 heartbeatTime

heartbeatTime is the last time at which the eviction process was reported to be in progress by the responder. It should reflect the present time when set. Responders should avoid heartbeats more frequent than 20 seconds to avoid overloading the control-plane.

=head2 message

message provides human-readable details about the state of the responder and the eviction process. Maximum length is 4000 characters.

=head2 name

name allows you to identify the responder reacting to the Eviction.

It must be a valid domain-prefixed key (such as "acme.io/foo"). This field is initialized by Kubernetes and must be unique for each responder. This field is required.

=head2 startTime

startTime tracks the time at which this responder was designated as active and should start processing the eviction request. It should reflect the present time when set. This field is initialized by Kubernetes when this responder becomes active. This field becomes immutable once set.

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
