package IO::K8s::ExternalSecrets::V1::ExternalSecretSyncWindows;
# ABSTRACT: SyncWindows optionally restricts when periodic refreshes may occur.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s kind    => Str, { required => 'schema', enum => [qw(allow deny)] };
k8s windows => ['+IO::K8s::ExternalSecrets::V1::ExternalSecretSyncWindowEntry'], { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ExternalSecretSyncWindows - SyncWindows optionally restricts when periodic refreshes may occur.

=head1 VERSION

version 1.108

=head2 kind

Kind applies to every window in the list.
"allow" -- syncs are permitted only while at least one window is active;
           all other times are blocked.
"deny"  -- syncs are blocked while any window is active;
           all other times are permitted.

=head2 windows

Windows is the list of schedule+duration pairs.

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
