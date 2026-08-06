# Google Auth Library for Perl

This is a Perl implementation of the Google Auth Library, based in part on the Ruby implementation. This library is not directly supported by Google.

https://github.com/googleapis/google-auth-library-ruby/

## Installation

Tests depend on OpenSSL. On Debian, install with `apt-get install libssl-dev`.

To build this module, run the following commands:

```bash
apt-get install liblocal-lib-perl libdatetime-perl libssl-dev \
        libnet-ssleay-perl gcc cpanminus libdist-zilla-perl
dzil authordeps --missing | cpanm
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm CryptX \
      Crypt::X509 \
      Crypt::OpenSSL::CA \
      Throwable::Error \
      Test::Exception \
      Test::LWP::UserAgent \
      Test::More \
      JSON::XS
perl Makefile.PL
make
make test
make install
```

## Support and Documentation

After installing, you can find documentation for this module with the `perldoc` command:

```bash
perldoc Google::Auth
```

You can also look for information at:

- **GitHub Issue Tracker:**  
  https://github.com/GoogleCloudPlatform/google-auth-library-perl/issues
- **RT, CPAN's request tracker:**  
  https://rt.cpan.org/Dist/Display.html?Name=Google-Auth
- **MetaCPAN:**  
  https://metacpan.org/release/Google-Auth

## License and Copyright

Copyright 2020 Google LLC and contributors

This program is released under the Apache 2.0 license.
