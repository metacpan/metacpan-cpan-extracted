package IO::K8s::Traefik::V1alpha1::EncodedCharacters;
# ABSTRACT: EncodedCharacters configures which encoded characters are allowed in the request path.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allowEncodedBackSlash     => Bool;
k8s allowEncodedHash          => Bool;
k8s allowEncodedNullCharacter => Bool;
k8s allowEncodedPercent       => Bool;
k8s allowEncodedQuestionMark  => Bool;
k8s allowEncodedSemicolon     => Bool;
k8s allowEncodedSlash         => Bool;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::EncodedCharacters - EncodedCharacters configures which encoded characters are allowed in the request path.

=head1 VERSION

version 1.108

=head2 allowEncodedBackSlash

AllowEncodedBackSlash defines whether requests with encoded back slash characters in the path are allowed.

=head2 allowEncodedHash

AllowEncodedHash defines whether requests with encoded hash characters in the path are allowed.

=head2 allowEncodedNullCharacter

AllowEncodedNullCharacter defines whether requests with encoded null characters in the path are allowed.

=head2 allowEncodedPercent

AllowEncodedPercent defines whether requests with encoded percent characters in the path are allowed.

=head2 allowEncodedQuestionMark

AllowEncodedQuestionMark defines whether requests with encoded question mark characters in the path are allowed.

=head2 allowEncodedSemicolon

AllowEncodedSemicolon defines whether requests with encoded semicolon characters in the path are allowed.

=head2 allowEncodedSlash

AllowEncodedSlash defines whether requests with encoded slash characters in the path are allowed.

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
