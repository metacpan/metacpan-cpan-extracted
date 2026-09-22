package IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatus;
# ABSTRACT: PushSecretStatus indicates the history of the status of PushSecret.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions            => ['+IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatusCondition'];
k8s refreshTime           => Time, { nullable => 1 };
k8s syncedPushSecrets     => { Str => 1 };
k8s syncedResourceVersion => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatus - PushSecretStatus indicates the history of the status of PushSecret.

=head1 VERSION

version 1.108

=head2 conditions

No description in the upstream schema.

=head2 refreshTime

refreshTime is the time and date the external secret was fetched and
the target secret updated

=head2 syncedPushSecrets

Synced PushSecrets, including secrets that already exist in provider.
Matches secret stores to PushSecretData that was stored to that secret store.

=head2 syncedResourceVersion

SyncedResourceVersion keeps track of the last synced version.

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
