package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionCondition;
# ABSTRACT: CustomResourceDefinitionCondition contains details for the current condition of this pod.
our $VERSION = '1.008';
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

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionCondition - CustomResourceDefinitionCondition contains details for the current condition of this pod.

=head1 VERSION

version 1.008

=head2 lastTransitionTime

lastTransitionTime last time the condition transitioned from one status to another.

=head2 message

message is a human-readable message indicating details about last transition.

=head2 reason

reason is a unique, one-word, CamelCase reason for the condition's last transition.

=head2 status

status is the status of the condition. Can be True, False, Unknown.

=head2 type

type is the type of the condition. Types include Established, NamesAccepted and Terminating.

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
