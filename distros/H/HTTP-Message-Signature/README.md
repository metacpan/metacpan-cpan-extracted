# NAME

HTTP::Message::Signature - Verify HTTP Message Signatures (RFC 9421)

# STATUS

This module is an experimental prototype.

The user interface is subject to change.

See also ["KNOWN ISSUES"](#known-issues) and ["SECURITY CONSIDERATIONS"](#security-considerations).

# SYNOPSIS

```perl
use HTTP::Message::Signature;

try {

    my $sig = HTTP::Message::Signature->new(
        message     => $request,         # HTTP::Request, Plack::Request or PSGI env hash
        require_tag => 'web-bot-auth',
    );

    $sig->is_expired and die "expired signature";

    $sig->verify or die "bad signature";

}
catch ($e) {

    ...

}
```

# DESCRIPTION

This module supports verifying HTTP Message Signatures (RFC 9421), notably those used for Web Bot Authentication.

# RECENT CHANGES

Changes for version v0.0.2 (2026-11-19)

- Bug Fixes
    - Removed use of "equ" operator and state hash variables that caused problems with older Perl versions.
    - Specify minimum version of List::Util.
- Documentation
    - Fixed broken Changes file.
    - Move STATUS section to the top.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Carp](https://metacpan.org/pod/Carp)
- [Crypt::PK::Ed25519](https://metacpan.org/pod/Crypt%3A%3APK%3A%3AEd25519) version 0.089 or later
- [HTTP::Message](https://metacpan.org/pod/HTTP%3A%3AMessage)
- [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny)
- [Hash::MultiValue](https://metacpan.org/pod/Hash%3A%3AMultiValue)
- [Hash::Ordered](https://metacpan.org/pod/Hash%3A%3AOrdered)
- [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS)
- [List::Util](https://metacpan.org/pod/List%3A%3AUtil) version 1.29 or later
- [MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64)
- [Moo](https://metacpan.org/pod/Moo)
- [PerlX::Maybe](https://metacpan.org/pod/PerlX%3A%3AMaybe)
- [Plack::Request](https://metacpan.org/pod/Plack%3A%3ARequest)
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [String::Util](https://metacpan.org/pod/String%3A%3AUtil)
- [Syntax::Keyword::Match](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3AMatch)
- [Types::Common](https://metacpan.org/pod/Types%3A%3ACommon)
- [Types::URI](https://metacpan.org/pod/Types%3A%3AURI)
- [URI](https://metacpan.org/pod/URI)
- [constant](https://metacpan.org/pod/constant)
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.24.0 or later

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan HTTP::Message::Signature
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SECURITY CONSIDERATIONS

## Structured Fields

The current version of this module uses regular expressions for splitting dictionary and parameter fields,
rather than using an HTTP Structured Field (RFC 9651) parser.

## Trusted Agents

Your application should use an allowed list of trusted agents, rather than attempt to verify arbitrary requests.

# SUPPORT

Only the latest release of this module will be supported.

This module requires Perl v5.24 or later.
Future releases may only support Perl versions released in the last ten (10) years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-HTTP-Message-Signature/issues](https://github.com/robrwo/perl-HTTP-Message-Signature/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-HTTP-Message-Signature](https://github.com/robrwo/perl-HTTP-Message-Signature)
and may be cloned from [https://github.com/robrwo/perl-HTTP-Message-Signature.git](https://github.com/robrwo/perl-HTTP-Message-Signature.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Apache License, Version 2.0, January 2004
```

# SEE ALSO

[Web Bot Auth](https://datatracker.ietf.org/wg/webbotauth/about/)

[HTTP Message Signatures for automated traffic](https://github.com/webbotauth/draft-ietf-webbotauth-httpsig-protocol/)

[RFC 7517: JSON Web Key (JWK)](https://www.rfc-editor.org/info/rfc7517)

[RFC 9421: HTTP Message Signatures](https://www.rfc-editor.org/info/rfc9421)

[RFC 9651: Structured Field Values for HTTP](https://www.rfc-editor.org/info/rfc9651)
