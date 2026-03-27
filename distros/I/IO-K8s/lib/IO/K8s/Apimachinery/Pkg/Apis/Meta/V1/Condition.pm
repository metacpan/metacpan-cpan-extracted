package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition;
# ABSTRACT: Condition contains details for one aspect of the current state of this API Resource.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s lastTransitionTime => Time, 'required';


k8s message => Str, 'required';


k8s observedGeneration => Int;


k8s reason => Str, 'required';


k8s status => Str, 'required';


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition - Condition contains details for one aspect of the current state of this API Resource.

=head1 VERSION

version 1.100

=head2 lastTransitionTime

lastTransitionTime is the last time the condition transitioned from one status to another. This should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.

=head2 message

message is a human readable message indicating details about the transition. This may be an empty string.

=head2 observedGeneration

observedGeneration represents the .metadata.generation that the condition was set based upon. For instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date with respect to the current state of the instance.

=head2 reason

reason contains a programmatic identifier indicating the reason for the condition's last transition. Producers of specific condition types may define expected values and meanings for this field, and whether the values are considered a guaranteed API. The value should be a CamelCase string. This field may not be empty.

=head2 status

status of the condition, one of True, False, Unknown.

=head2 type

type of condition in CamelCase or in foo.example.com/CamelCase.

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
