package IO::K8s::Api::Core::V1::ComponentCondition;
# ABSTRACT: Information about the condition of a component.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s error => Str;


k8s message => Str;


k8s status => Str, 'required';


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ComponentCondition - Information about the condition of a component.

=head1 VERSION

version 1.008

=head2 error

Condition error code for a component. For example, a health check error code.

=head2 message

Message about the condition for a component. For example, information about a health check.

=head2 status

Status of the condition for a component. Valid values for "Healthy": "True", "False", or "Unknown".

=head2 type

Type of condition for a component. Valid value: "Healthy"

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
