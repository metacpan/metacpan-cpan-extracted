package IO::K8s::ExternalSecrets::V1::ExternalSecretRewriteMerge;
# ABSTRACT: Used to merge key/values in one single Secret The resulting key will contain all values from the specified secrets
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conflictPolicy => Str, { enum => [qw(Ignore Error)], default => 'Error' };
k8s into           => Str, { default => '' };
k8s priority       => [Str];
k8s priorityPolicy => Str, { enum => [qw(IgnoreNotFound Strict)], default => 'Strict' };
k8s strategy       => Str, { enum => [qw(Extract JSON)], default => 'Extract' };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ExternalSecretRewriteMerge - Used to merge key/values in one single Secret The resulting key will contain all values from the specified secrets

=head1 VERSION

version 1.108

=head2 conflictPolicy

Used to define the policy to use in conflict resolution.

=head2 into

Used to define the target key of the merge operation.
Required if strategy is JSON. Ignored otherwise.

=head2 priority

Used to define key priority in conflict resolution.

=head2 priorityPolicy

Used to define the policy when a key in the priority list does not exist in the input.

=head2 strategy

Used to define the strategy to use in the merge operation.

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
