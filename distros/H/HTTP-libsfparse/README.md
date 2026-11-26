# NAME

HTTP::StructuredField - parse RFC 9651 HTTP Structured Fields

# SYNOPSIS

```perl
use HTTP::StructuredField;

try {

    my $dict = HTTP::StructuredField->parse_dictionary( $msg->header("signature-input") );
    for my $key ( keys $dist->%* ) {

        my $input = $dict->{$key};
        $input->is_inner_list or die "list expected";

        my @items = $input->value->@*;

  }


}
catch ($error) {
  ...
}
```

# DESCRIPTION

This is an object-oriented wrapper around [HTTP::libsfparse](https://metacpan.org/pod/HTTP%3A%3Alibsfparse), for correctly parsing
[RFC 9651](https://www.rfc-editor.org/info/rfc9651/) HTTP Structured Fields.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Exporter](https://metacpan.org/pod/Exporter) version 5.57 or later
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [Sub::Util](https://metacpan.org/pod/Sub%3A%3AUtil)
- [XSLoader](https://metacpan.org/pod/XSLoader)
- [experimental](https://metacpan.org/pod/experimental)
- [perl](https://metacpan.org/pod/perl) version v5.20.0 or later
- [strict](https://metacpan.org/pod/strict)
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan HTTP::StructuredField
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

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SUPPORT

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-HTTP-StructuredField/issues](https://github.com/robrwo/perl-HTTP-StructuredField/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-HTTP-StructuredField](https://github.com/robrwo/perl-HTTP-StructuredField)
and may be cloned from [https://github.com/robrwo/perl-HTTP-StructuredField.git](https://github.com/robrwo/perl-HTTP-StructuredField.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The XS wrapper [HTTP::libsfparse](https://metacpan.org/pod/HTTP%3A%3Alibsfparse) was written with the assistance of Claude Opus.

# CONTRIBUTOR

Paul Johnson <paul@pjcj.net>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

```
The MIT (X11) License
```

The bundled copy of libsfparse is Copyright (c) 2023 Tatsuhiro Tsujikawa and other sfparse contributors.
It is included unmodified.
