package IO::K8s::Cilium::V2::HeaderMatch;
# ABSTRACT: HeaderMatch extends the HeaderValue for matching requirement of a named header field against an immediate string or a secret value.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s mismatch => Str, { enum => [qw(LOG ADD DELETE REPLACE)] };
k8s name     => Str, { required => 'schema' };
k8s secret   => 'Core::V1::SecretReference';
k8s value    => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::HeaderMatch - HeaderMatch extends the HeaderValue for matching requirement of a named header field against an immediate string or a secret value.

=head1 VERSION

version 1.108

=head2 mismatch

Mismatch identifies what to do in case there is no match. The default is
to drop the request. Otherwise the overall rule is still considered as
matching, but the mismatches are logged in the access log.

=head2 name

Name identifies the header.

=head2 secret

Secret refers to a secret that contains the value to be matched against.
The secret must only contain one entry. If the referred secret does not
exist, and there is no "Value" specified, the match will fail.

=head2 value

Value matches the exact value of the header. Can be specified either
alone or together with "Secret"; will be used as the header value if the
secret can not be found in the latter case.

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
