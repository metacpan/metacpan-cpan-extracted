package IO::K8s::ExternalSecrets::V1alpha1::PasswordSpec;
# ABSTRACT: PasswordSpec controls the behavior of the password generator.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allowRepeat      => Bool, { required => 'schema', default => 0 };
k8s digits           => Int;
k8s encoding         => Str, { enum => [qw(base64 base64url base32 hex raw)], default => 'raw' };
k8s length           => Int, { required => 'schema', default => 24 };
k8s noUpper          => Bool, { required => 'schema', default => 0 };
k8s secretKeys       => [Str];
k8s symbolCharacters => Str;
k8s symbols          => Int;









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::PasswordSpec - PasswordSpec controls the behavior of the password generator.

=head1 VERSION

version 1.108

=head2 allowRepeat

set AllowRepeat to true to allow repeating characters.

=head2 digits

Digits specifies the number of digits in the generated
password. If omitted it defaults to 25% of the length of the password

=head2 encoding

Encoding specifies the encoding of the generated password.
Valid values are:
- "raw" (default): no encoding
- "base64": standard base64 encoding
- "base64url": base64url encoding
- "base32": base32 encoding
- "hex": hexadecimal encoding

=head2 length

Length of the password to be generated.
Defaults to 24

=head2 noUpper

Set NoUpper to disable uppercase characters

=head2 secretKeys

SecretKeys defines the keys that will be populated with generated passwords.
Defaults to "password" when not set.

=head2 symbolCharacters

SymbolCharacters specifies the special characters that should be used
in the generated password.

=head2 symbols

Symbols specifies the number of symbol characters in the generated
password. If omitted it defaults to 25% of the length of the password

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
