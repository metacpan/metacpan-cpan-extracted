package IO::K8s::Api::Coordination::V1::LeaseSpec;
# ABSTRACT: LeaseSpec is a specification of a Lease.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s acquireTime => Time;


k8s holderIdentity => Str;


k8s leaseDurationSeconds => Int;


k8s leaseTransitions => Int;


k8s preferredHolder => Str;


k8s renewTime => Time;


k8s strategy => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Coordination::V1::LeaseSpec - LeaseSpec is a specification of a Lease.

=head1 VERSION

version 1.009

=head2 acquireTime

acquireTime is a time when the current lease was acquired.

=head2 holderIdentity

holderIdentity contains the identity of the holder of a current lease. If Coordinated Leader Election is used, the holder identity must be equal to the elected LeaseCandidate.metadata.name field.

=head2 leaseDurationSeconds

leaseDurationSeconds is a duration that candidates for a lease need to wait to force acquire it. This is measured against the time of last observed renewTime.

=head2 leaseTransitions

leaseTransitions is the number of transitions of a lease between holders.

=head2 preferredHolder

PreferredHolder signals to a lease holder that the lease has a more optimal holder and should be given up. This field can only be set if Strategy is also set.

=head2 renewTime

renewTime is a time when the current holder of a lease has last updated the lease.

=head2 strategy

Strategy indicates the strategy for picking the leader for coordinated leader election. If the field is not specified, there is no active coordination for this lease. (Alpha) Using this field requires the CoordinatedLeaderElection feature gate to be enabled.

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
