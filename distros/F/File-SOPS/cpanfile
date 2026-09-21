requires 'perl', '5.014';

requires 'Crypt::Age', '0.004';
requires 'CryptX';
requires 'YAML::XS';
# Only used to recover document key order for MAC verification; YAML::XS stays
# the parser and emitter. See the MAC section of File::SOPS.
requires 'YAML::PP';
# JSON::MaybeXS is used for JSON::PP::Boolean (JSON->true/false), which every
# one of its backends agrees on. It is NOT what emits or parses documents:
# it binds a backend once per process by load order, so the calling program
# decided our wire bytes, and the backends disagree on floats in ways that
# break MAC verification in both directions. Format::JSON names
# Cpanel::JSON::XS instead -- see docs/adr/0005. The version is the one
# JSON::MaybeXS itself asks for, so this is usually already installed.
requires 'JSON::MaybeXS';
requires 'Cpanel::JSON::XS', '4.38';
requires 'Moo';
requires 'namespace::clean';

on test => sub {
    requires 'File::Slurper';
};

on develop => sub {
    # xt/author/pod-links.t checks L<> resolution over the WOVEN pod (Test::Pod,
    # a separate develop-phase prereq registered by [PodSyntaxTests] itself,
    # only checks syntax) -- see k98.
    requires 'Pod::Checker';
};
