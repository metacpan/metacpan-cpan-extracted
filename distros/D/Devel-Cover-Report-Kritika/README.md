# NAME

Devel::Cover::Report::Kritika - Cover reporting to Kritika

# SYNOPSIS

    export KRITIKA_TOKEN=yourtoken
    cover -test -report kritika

# DESCRIPTION

[Devel::Cover::Report::Kritika](https://metacpan.org/pod/Devel::Cover::Report::Kritika) reports coverage to [Kritika](https://kritika.io).

In order to submit the report, you have to set KRITIKA\_TOKEN environmental variable to the appropriate token, which can
be obtained from Kritika web interface.

# INTEGRATION

[Devel::Cover::Report::Kritika](https://metacpan.org/pod/Devel::Cover::Report::Kritika) was written having in mind the integration possibility with many public/private CI/CD
services.

It will detect the following services:

- [Travis CI](https://travis-ci.org/)
- [GitLab](https://about.gitlab.com/gitlab-ci/)

# DEVELOPMENT

## Repository

    http://github.com/kritikaio/devel-cover-report-kritika-perl

# CREDITS

# AUTHOR

Viacheslav Tykhanovskyi, `vti@cpan.org`.

# COPYRIGHT AND LICENSE

Copyright (C) 2017, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
