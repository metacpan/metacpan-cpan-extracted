package Kubernetes::REST::Storage;
our $VERSION = '1.107';
# ABSTRACT: Compatibility helper for deprecated v0 Storage calls
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Storage' });


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Storage - Compatibility helper for deprecated v0 Storage calls

=head1 VERSION

version 1.107

=head1 SYNOPSIS

    # Old way (deprecated):
    my $scs = $api->Storage->ListStorageClass();

    # New way:
    my $scs = $api->list('StorageClass');

=head1 DESCRIPTION

This module keeps the deprecated v0 API usable. Kubernetes::REST 0.01/0.02 (by JLMARTIN) used method names like C<< $api->Storage->ListStorageClass(...) >>; calls like that still reach the cluster from here, translated onto the v1 API.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->list('StorageClass')
    $api->list('VolumeAttachment')
    $api->create($storageclass)

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

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

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
