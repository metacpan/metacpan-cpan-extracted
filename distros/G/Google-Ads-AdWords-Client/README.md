# AdWords API Perl Client Library

[![CPAN version](https://badge.fury.io/pl/Google-Ads-AdWords-Client.svg)](https://badge.fury.io/pl/Google-Ads-AdWords-Client)

Google's [AdWords API](https://developers.google.com/adwords/api/) service lets developers design computer programs that
interact directly with the [AdWords
platform](https://adwords.google.com/select/Login). With these applications,
advertisers and third parties can more efficiently -- and creatively -- manage
their large or complex [AdWords](https://adwords.google.com/select/Login) accounts and campaigns.

[AdWords API](https://developers.google.com/adwords/api/) Perl Client Library makes it easier to write Perl clients to
programmatically access [AdWords](https://adwords.google.com/select/Login) accounts.

## Features
 - Fully featured object oriented client library (all classes come generated from
 - the WSDLs)
 - Perl 5.14.0+ and based on SOAP::WSDL module
 - Outgoing and incoming SOAP message are monitored and logged on demand
 - Support for API calls to production system or sandbox
 - OAuth2 Support
 - Loading of credentials from local file or source code
 - Online
   [documentation](https://metacpan.org/release/Google-Ads-AdWords-Client)

## Getting started

***NOTE:*** If you are using Windows, go through the instructions under ***What if I'm using Windows?*** first before continuing here.

- Download the newest version from [releases](https://github.com/googleads/googleads-perl-lib/releases) or from [CPAN Google::Ads::AdWords::Client](http://search.cpan.org/~sundquist/).

- Install dependencies.

  ```
  $ perl Build.PL
  $ perl Build installdeps
  ```

- Copy the sample **adwords.properties** for your product to your home directory
and fill out the required properties.

  * [AdWords adwords.properties](https://github.com/googleads/googleads-perl-lib/blob/master/adwords.properties)

- Setup your OAuth2 credentials.

  The AdWords API uses
[OAuth2](http://oauth.net/2/) as the authentication mechanism. Follow the appropriate guide below based on your use case.

  **If you're accessing an API using your own credentials...**

  * [Using AdWords](https://github.com/googleads/googleads-perl-lib/wiki/API-access-using-own-credentials-(installed-application-flow))

  **If you're accessing an API on behalf of clients...**

  * [Developing a web application](https://github.com/googleads/googleads-perl-lib/wiki/API-Access-on-behalf-of-your-clients-(web-flow))

## How do I use the library?
There are code examples for most of the common use cases in the [repository](https://github.com/googleads/googleads-perl-lib/tree/master/examples). These code examples are also available as part of the [release distributions](https://github.com/googleads/googleads-perl-lib/releases). You can also refer to the [wiki articles](https://github.com/googleads/googleads-perl-lib/wiki/_pages) for additional documentation.

### How do I run the examples?

Examples can be run by executing the following on the command line
from a sub-directory of the `examples/` directory,

  ```
  $ perl Example.pl
  ```

Some examples require you replace object IDs in where you see placeholder
like `INSERT_***_HERE`

### How do I enable logging?

The client library uses a custom class for all logging. Check out our [logging guide on GitHub](https://github.com/googleads/googleads-perl-lib/wiki/Logging) for more details.

### What if I'm using Windows?

The library is only supported on Windows for ActivePerl 5.14+ x86 (32bit version).

Before following the **Getting started** steps:

  * Install the MinGW module by executing `ppm install MinGW` in the command prompt.
  * Install OpenSSL, which can be found at: https://code.google.com/p/openssl-for-windows/.
  * If `installdeps` errors on `Crypt::OpenSSL::RSA` stating that it cannot find .h files:
   - Note the root location of your openssl installation. This will be referred
   to as `<openssl_dir>` e.g. `C:\openssl`. Note the root location or your Perl
   installation e.g. `C:\Perl`. This will be referred to as `<perl_dir>`.
   - Copy the `<openssl_dir>\include directory` to `<perl_dir>\lib\CORE`.
   - Copy all the .dll files in `<openssl_dir>\bin` to `<perl_dir>\lib\CORE`.
   - Copy all the .lib files in `<openssl_dir>\lib` to `<perl_dir>\lib\CORE`.

## How do I Contribute?
See the [guidelines for contributing](https://github.com/googleads/googleads-perl-lib/blob/master/CONTRIBUTING.md) for details.

## Where do I report issues?
Please report issues at <https://github.com/googleads/googleads-perl-lib/issues>

## Support forum
If you have questions about the client library or AdWords API, you can ask them at the [AdWords API Forum](https://groups.google.com/group/adwords-api?pli=1).

## Authors
  - Jeff Posnick
  - David Torres

## Maintainers
  - Josh Radcliff
  - Nadine Sundquist
