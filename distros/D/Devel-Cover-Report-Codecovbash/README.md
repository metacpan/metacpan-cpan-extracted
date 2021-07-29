# NAME

Devel::Cover::Report::Codecovbash - Generate a JSON file to be uploaded with the codecov bash script.

# VERSION

version 0.04

# DESCRIPTION

This is a coverage reporter for Codecov. It generates a JSON file that can be
uploaded with the bash script provided by codecov. See
[https://docs.codecov.io/docs/about-the-codecov-bash-uploader](https://docs.codecov.io/docs/about-the-codecov-bash-uploader) for details.

The generated file will be named `codecov.json` and will be in the
`cover_db` directory by default.

Nearly all of the code in this distribution was simply copied from Pine
Mizune's
[Devel-Cover-Report-Codecov](https://metacpan.org/release/Devel-Cover-Report-Codecov)
distribution.

# UPLOADING RESULTS

Use the codecov bash script:

    cover -report codecovbash
    bash <(curl -s https://codecov.io/bash) -t token -f cover_db/codecov.json

# SUPPORT

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Devel-Cover-Report-Codecovbash can be found at [https://github.com/perlpunk/Devel-Cover-Report-Codecovbash](https://github.com/perlpunk/Devel-Cover-Report-Codecovbash).

# AUTHOR

Tina Müller <tinita@cpan.org>

# CONTRIBUTORS

- Dave Rolsky <autarch@urth.org>
- Tina Müller <cpan2@tinita.de>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 - 2021 by Pine Mizune.

This is free software, licensed under:

    The MIT (X11) License

The full text of the license can be found in the
`LICENSE` file included with this distribution.
