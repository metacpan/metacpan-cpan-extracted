package IO::K8s::Api::Flowcontrol::V1beta3::PriorityLevelConfigurationSpec;
# ABSTRACT: PriorityLevelConfigurationSpec specifies the configuration of a priority level.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s exempt => 'Flowcontrol::V1beta3::ExemptPriorityLevelConfiguration';


k8s limited => 'Flowcontrol::V1beta3::LimitedPriorityLevelConfiguration';


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Flowcontrol::V1beta3::PriorityLevelConfigurationSpec - PriorityLevelConfigurationSpec specifies the configuration of a priority level.

=head1 VERSION

version 1.006

=head2 exempt

C<exempt> specifies how requests are handled for an exempt priority level. This field MUST be empty if C<type> is C<"Limited">. This field MAY be non-empty if C<type> is C<"Exempt">. If empty and C<type> is C<"Exempt"> then the default values for C<ExemptPriorityLevelConfiguration> apply.

=head2 limited

C<limited> specifies how requests are handled for a Limited priority level. This field must be non-empty if and only if C<type> is C<"Limited">.

=head2 type

C<type> indicates whether this priority level is subject to limitation on request execution. A value of C<"Exempt"> means that requests of this priority level are not subject to a limit (and thus are never queued) and do not detract from the capacity made available to other priority levels. A value of C<"Limited"> means that (a) requests of this priority level _are_ subject to limits and (b) some of the server's limited capacity is made available exclusively to this priority level. Required.

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
