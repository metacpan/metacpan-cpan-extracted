# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [OPTIONS](#options)
* [EXAMPLE LOG4PERL CONFIGURATION](#example-log4perl-configuration)
  * [Use Environment Variables (Best Practice)](#use-environment-variables-best-practice)
  * [Specify Credentials](#specify-credentials)
* [AUTHENTICATION](#authentication)
* [AUTHOR](#author)
* [LICENSE](#license)
* [SEE ALSO](#see-also)
---
[Back to Table of Contents](#table-of-contents)

# NAME

Log::Log4perl::Appender::AmazonSES - Send via Amazon SES (SMTP over TLS)

[Back to Table of Contents](#table-of-contents)

# SYNOPSIS

     use Log::Log4perl::Appender::AmazonSES;

     my $app = Log::Log4perl::Appender::AmazonSES->new(
       Host    => 'email-smtp.us-east-1.amazonaws.com',
       Port    => '465'
       Hello   => 'localhost.localdomain',
       Timeout => 2,
       Debug   => 0,
       from    => 'me@example.com',
       to      => 'you@example.com',
       subject => 'Alert: there has been an error',
     );

     $app->log(message => "A message via Amazon SES email");

[Back to Table of Contents](#table-of-contents)

# DESCRIPTION

This appender uses the [Net::SMTP](https://metacpan.org/pod/Net%3A%3ASMTP) module to send mail via Amazon
SES. Essentially a flavor of [Log::Log4perl::Appender::Net::SMTP](https://metacpan.org/pod/Log%3A%3ALog4perl%3A%3AAppender%3A%3ANet%3A%3ASMTP) with
some intelligent options and restrictions.

This module was created to provide a straightforward, well-documented
method for sending Log4perl alerts via Amazon SES. While other email
appenders exist, getting them to work with modern, authenticated SMTP
services can be challenging due to outdated dependencies or sparse
documentation. This appender aims to "just work" by using Net::SMTP
directly with the necessary options for SES.

[Back to Table of Contents](#table-of-contents)

# OPTIONS

- **from** (required)

    The email address of the sender.

- **to** (required)

    The email address of the recipient. You can put several addresses separated
    by a comma.

- **subject** (required)

    The subject of the email.

- **Other Net::SMTP options**
    - Hello

        Defaults to your fully qualified host's name. You can also use `domain`.

    - Port

        Default port for connection to the SMTP mail host. Amazon supports 25,
        465, 587, 2587. The connection will be upgrade to SSL for non-SSL
        ports.

        Default: 465

    - Debug

        Outputs debug information from Net:::SMTP

        Default: false

[Back to Table of Contents](#table-of-contents)

# EXAMPLE LOG4PERL CONFIGURATION

## Use Environment Variables (Best Practice)

    log4perl.rootLogger = INFO, Mailer
    log4perl.appender.Mailer = Log::Log4perl::Appender::AmazonSES
    log4perl.appender.Mailer.from       = ...
    log4perl.appender.Mailer.to         = ...
    log4perl.appender.Mailer.subject    = ...
    log4perl.appender.Mailer.layout = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Mailer.layout.ConversionPattern = %d - %p > %m%n

## Specify Credentials

    log4perl.rootLogger = INFO, Mailer
    log4perl.appender.Mailer = Log::Log4perl::Appender::AmazonSES
    log4perl.appender.Mailer.from       = ...
    log4perl.appender.Mailer.to         = ...
    log4perl.appender.Mailer.subject    = ...
    log4perl.appender.Mailer.auth.user       = <YOUR AMAZON SES USER>
    log4perl.appender.Mailer.auth.password   = <YOUR AMAZON SES PASSWORD>
    log4perl.appender.Mailer.layout = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Mailer.layout.ConversionPattern = %d - %p > %m%n

[Back to Table of Contents](#table-of-contents)

# AUTHENTICATION

You must either supply your authentication parameters in the
configuration of set SES\_SMTP\_USER and SES\_SMTP\_PASS environment
variables.

[Back to Table of Contents](#table-of-contents)

# AUTHOR

Rob Lauer - <bigfoot@cpan.org>

[Back to Table of Contents](#table-of-contents)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

[Back to Table of Contents](#table-of-contents)

# SEE ALSO

[Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl), [Net::SMTP](https://metacpan.org/pod/Net%3A%3ASMTP)
