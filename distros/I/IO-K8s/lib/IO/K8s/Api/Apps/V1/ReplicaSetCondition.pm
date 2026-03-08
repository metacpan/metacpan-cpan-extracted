package IO::K8s::Api::Apps::V1::ReplicaSetCondition;
# ABSTRACT: ReplicaSetCondition describes the state of a replica set at a certain point.
our $VERSION = '1.006';
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

IO::K8s::Api::Apps::V1::ReplicaSetCondition - ReplicaSetCondition describes the state of a replica set at a certain point.

=head1 VERSION

version 1.006

=head2 lastTransitionTime

The last time the condition transitioned from one status to another.

=head2 message

A human readable message indicating details about the transition.

=head2 reason

The reason for the condition's last transition.

=head2 status

Status of the condition, one of True, False, Unknown.

=head2 type

Type of replica set condition.

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
