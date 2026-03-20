package IO::K8s::Api::Coordination::V1alpha1::LeaseCandidateSpec;
# ABSTRACT: LeaseCandidateSpec is a specification of a Lease.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s binaryVersion => Str;


k8s emulationVersion => Str;


k8s leaseName => Str, 'required';


k8s pingTime => Time;


k8s preferredStrategies => [Str], 'required';


k8s renewTime => Time;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Coordination::V1alpha1::LeaseCandidateSpec - LeaseCandidateSpec is a specification of a Lease.

=head1 VERSION

version 1.009

=head2 binaryVersion

BinaryVersion is the binary version. It must be in a semver format without leading `v`. This field is required when strategy is "OldestEmulationVersion"

=head2 emulationVersion

EmulationVersion is the emulation version. It must be in a semver format without leading `v`. EmulationVersion must be less than or equal to BinaryVersion. This field is required when strategy is "OldestEmulationVersion"

=head2 leaseName

LeaseName is the name of the lease for which this candidate is contending. This field is immutable.

=head2 pingTime

PingTime is the last time that the server has requested the LeaseCandidate to renew. It is only done during leader election to check if any LeaseCandidates have become ineligible. When PingTime is updated, the LeaseCandidate will respond by updating RenewTime.

=head2 preferredStrategies

PreferredStrategies indicates the list of strategies for picking the leader for coordinated leader election. The list is ordered, and the first strategy supersedes all other strategies. The list is used by coordinated leader election to make a decision about the final election strategy. This follows as - If all clients have strategy X as the first element in this list, strategy X will be used. - If a candidate has strategy [X] and another candidate has strategy [Y, X], Y supersedes X and strategy Y will be used. - If a candidate has strategy [X, Y] and another candidate has strategy [Y, X], this is a user error and leader election will not operate the Lease until resolved. (Alpha) Using this field requires the CoordinatedLeaderElection feature gate to be enabled.

=head2 renewTime

RenewTime is the time that the LeaseCandidate was last updated. Any time a Lease needs to do leader election, the PingTime field is updated to signal to the LeaseCandidate that they should update the RenewTime. Old LeaseCandidate objects are also garbage collected if it has been hours since the last renew. The PingTime field is updated regularly to prevent garbage collection for still active LeaseCandidates.

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
