# NAME

MVC::Neaf [ni:f] stands for Not Even A Framework.

# OVERVIEW

Neaf offers a simple, yet powerful way to create simple web-applications.
By the lazy, for the lazy.

It has a lot of similarities to
[Dancer](https://metacpan.org/pod/Dancer2) and
[Kelp](https://metacpan.org/pod/Kelp).

**Model** is assumed to be a regular Perl module, and is totally out of scope.

**View** is assumed to have just one method, `render()`,
which receives a hashref and returns a pair of (content, content-type).

**Controller** is reduced to just one function, which gets a request object
and is expected to return a hashref.

A pre-defined set of dash-prefixed control keys allows to control the
framework's behaviour while all other keys are just sent to the view.

**Request** object will depend on the underlying web-server.
The same app, verbatim, should be able to run as PSGI app, CGI script, or
Apache handler.
Request knows all you need to know about the outside world.

# EXAMPLE

The following would produce a greeting message depending
on the `?name=` parameter.

    use strict;
    use warnings;
    use MVC::Neaf qw(:sugar);

    get + post "/" => sub {
		my $req = shift;

		return {
			-template => \'Hello, [% name %]!',
			-type     => 'text/plain',
			name      => $req->param( name => qr/\w+/, "Stranger" ),
		},
    };

    neaf->run;

# FEATURES

* GET, POST, and HEAD requests; uploads; redirects; and cookies
are supported.
Not quite impressive, but it's 95% of what's needed 95% of the time.

* Template::Toolkit view out of the box;

* json/jsonp view out of the box (with sanitized callbacks);

* can serve raw content (e.g. generated images);

* can serve static files.
No need for separate web server to test your CSS/images.

* sanitized query parameters and cookies out of the box.

* Easy to develop RESTful web-services.

# NOT SO BORING FEATURES

* Fine-grained hooks and path-based default values;

* Delayed and/or unspecified length replies supported;

* Form validation with resubmission ability.
[Validator::LIVR](https://metacpan.org/pod/Validator::LIVR)
supported, but not requires.

* CLI-based debugging via `perl <your_app.pl> --help|--list|--method GET`

* Sessions supported out of the box with cookie-based and SQL-based backends.

* Fancy error templates supported.

# MORE EXAMPLES

The `example/` directory has a number of them, including an app explaining
HTTP in a nutshell, jsonp call sample and some stupid 200-line wiki engine.

In fact, the current development model relies on these examples
as an additional test suite, and no major feature is considered complete
until half a page micro-app can be written to demonstrate it works.

# PHILOSOPHY

* Start out simple, then scale up.

* Don't rely on side effects. Use *explicit* functions receiving *arguments*
and returning *a value*.

* Zeroconf: everything can be configured, nothing needs to.

* It's not software unless you can run it.

* Trust nobody. Validate the data.

* Force UTF8 if possible. It's 21st century.

# BUGS

This package is still under heavy development
(with a test coverage of about 80% though).

* mod\_perl handler is a mess (but it works somehow);

* native form validator is a joke;

* too few session mechanisms.

Bug reports, patches, and proposals are welcome.

# CONTRIBUTING TO THIS PROJECT

Please see STYLE.md for the style guide.
Please see CHECKLIST if you plan a new major version.

# ACKNOWLEDGEMENTS

[Eugene Ponizovsky](https://github.com/iph0)
had great influence over my understanding of MVC.

[Alexander Kuklev](https://github.com/akuklev)
gave some great early feedback
and also drove me towards functional programming and pure functions.

[Akzhan Abdulin](https://github.com/akzhan)
tricked me into making the hooks.

Ideas were shamelessly stolen from PSGI, Dancer, and Catalyst.

# LICENSE AND COPYRIGHT

Copyright 2016 Konstantin S. Uvarin aka KHEDIN

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

