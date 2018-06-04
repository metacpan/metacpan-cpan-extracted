# NAME

MVC::Neaf `[ni:f]` stands for **Not Even A Framework**.

# OVERVIEW

The following code can be run as a PSGI application or CGI script:

        use strict;
        use warnings;
        use MVC::Neaf;

        get + post "/" => sub {
            my $req = shift;

            return {
                -view     => 'TT',
                -template => \'Hello, [% name %]!',
                -type     => 'text/plain',
                name      => $req->param( name => qr/\w+/, "Stranger" ),
            };
        };

        neaf->run;

Just like many other frameworks, Neaf organises an application
into a *prefix tree* of routes. Each *route* has a *handler* `sub`
which receives one and only argument - a *request* object.

The *request* contains *everything* the application needs to know
about the outside world.

The *handler* must either *return* a hash for rendering, or *die*.
A 3-digit exception is a valid way of returning a configurable error page.

The *return hash* may contain dash-prefixed keys to control Neaf itself.
For instance, the default view is JSON-based but adding 

        -view => 'TT', -template => 'my.tpl'

to the hash would result in using `Template::Toolkit` instead.

# NOTABLE FEATURES

* **Mandatory validation** - parameters and cookies are always regex-checked.

* **Forms** that validate a bunch of input parameters, additionally
producing hashes of errors and raw values for resubmission.

* **Path-based defaults** that can be overridden in route definition or
by controller itself:

        neaf default => { -view => 'JS', version => $VERSION }, path => '/api';

* **Hooks** that may be executed at different stages:

        neaf pre_logic => sub {
            my $req = shift;
            die 403 unless $req->session->{is_admin};
        }, path => '/admin';

* **Easy CLI debugging** - see `perl myapp.pl --help`

See [examples](example/) for more.

# INSTALLATION

To install this module, run the following commands:

        perl Makefile.PL
        make
        make test
        make install

# BUGS

This package is still under heavy development
(with a test coverage of about 80% though).

Use [github](https://github.com/dallaylaen/perl-mvc-neaf/issues)
or [CPAN RT](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MVC-Neaf)
to report bugs and propose features.

Bug reports, feature requests, and overall critique are welcome.

# CONTRIBUTING TO THIS PROJECT

See [STYLE.md](STYLE.md) for the style guide.

See [CHECKLIST](CHECKLIST) if you plan to release a version.

See [TODO](TODO) for a rough development plan.
It changes rapidly though.

# LICENSE AND COPYRIGHT

Copyright 2016-2017 Konstantin S. Uvarin aka KHEDIN

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

