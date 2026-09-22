package IO::K8s::ExternalSecrets::V1::CacheConfig;
# ABSTRACT: Cache configures client-side caching for read operations (GetSecret, GetSecretMap).
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s maxSize => Int, { minimum => 1, default => 100 };
k8s ttl     => Str, { default => '5m' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::CacheConfig - Cache configures client-side caching for read operations (GetSecret, GetSecretMap).

=head1 VERSION

version 1.108

=head2 maxSize

MaxSize is the maximum number of secrets to cache.
When the cache is full, least-recently-used entries are evicted.

=head2 ttl

TTL is the time-to-live for cached secrets.
Format: duration string (e.g., "5m", "1h", "30s")

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
