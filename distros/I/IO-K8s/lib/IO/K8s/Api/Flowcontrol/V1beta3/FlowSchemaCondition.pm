package IO::K8s::Api::Flowcontrol::V1beta3::FlowSchemaCondition;
# ABSTRACT: FlowSchemaCondition describes conditions for a FlowSchema.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s lastTransitionTime => Time;


k8s message => Str;


k8s reason => Str;


k8s status => Str;


k8s type => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Flowcontrol::V1beta3::FlowSchemaCondition - FlowSchemaCondition describes conditions for a FlowSchema.

=head1 VERSION

version 1.009

=head2 lastTransitionTime

C<lastTransitionTime> is the last time the condition transitioned from one status to another.

=head2 message

C<message> is a human-readable message indicating details about last transition.

=head2 reason

C<reason> is a unique, one-word, CamelCase reason for the condition's last transition.

=head2 status

C<status> is the status of the condition. Can be True, False, Unknown. Required.

=head2 type

`type` is the type of the condition. Required.

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
