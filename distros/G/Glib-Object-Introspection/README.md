Glib::Object::Introspection
===========================

Glib::Object::Introspection uses the gobject-introspection and libffi projects
to dynamically create Perl bindings for a wide variety of libraries.  Examples
include GTK, WebKitGTK, libsoup and many more.


INSTALLATION
------------

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install


DEPENDENCIES
------------

Glib::Object::Introspection needs this C library:

| pkg-config module         | version   |
|---------------------------|-----------|
| gobject-introspection-1.0 | >= 0.10.0 |

and these Perl modules:

| Perl module         | version  |
|---------------------|----------|
| ExtUtils::Depends   | >= 0.300 |
| ExtUtils::PkgConfig | >= 1.000 |
| Glib                | >= 1.320 |


HOW TO CONTACT US
-----------------

- [gtk2-perl project homepage](http://gtk2-perl.sourceforge.net/)
- [Discourse](https://discourse.gnome.org/tag/perl)
- [Mailing list archives](https://mail.gnome.org/archives/gtk-perl-list/)
- [Matrix](https://matrix.to/#/#perl:gnome.org)
- [Issue tracker](https://gitlab.gnome.org/GNOME/perl-glib-object-introspection/-/issues)
- Email address for RT: bug-Glib-Object-Introspection [at] rt.cpan.org

Please do not contact any of the maintainers directly unless they ask you to.
The first point of contact for questions is the Discourse forum.


BUG REPORTS
-----------

For help with problems, please use Discourse first. If you already know you
have a bug, please file it with one of the bug trackers below.

With any problems and/or bug reports, it's always helpful for the developers
to have the following information:

- A small script that demonstrates the problem; this is not required, however,
  it will get your issue looked at much faster than a description of the
  problem alone.
- Version of Perl (perl -v)
- Versions of Glib/GTK modules (Glib/Gtk2/Pango/Cairo)
- Optional, but nice to have: versions of GTK libraries on your system
  (libglib, libgtk, libpango, libcairo, etc.)

There are multiple project bug trackers, please choose the one you are most
comfortable with using and/or already have an account for.

Project issue tracker:

- https://gitlab.gnome.org/GNOME/perl-glib-object-introspection/-/issues/new

Request Tracker:

- submitting bugs via the Web (requires a PAUSE account/Bitcard):
  https://rt.cpan.org/Public/Bug/Report.html?Queue=Glib-Object-Introspection
- submitting bugs via e-mail (open to anyone with e-mail):
  bug-Glib-Object-Introspection [at] rt.cpan.org

CONTRIBUTING
------------

The preferred form of contribution is through merge requests opened on the
GitLab project.

Fork the project using the GitLab web user interface into your own namespace,
and the clone from your fork:

    git clone https://gitlab.gnome.org/yourname/perl-glib-object-introspection.git
    cd perl-glib-object-introspection

Create a branch to work on your changes. The name of the branch should be
relevant to what you're working on; for instance, if you are fixing a bug
you should reference the issue number in the branch name, e.g.

    git switch -C issue-123

Once you've finished working on the bug fix or feature, push the branch
to the Git repository and open a new merge request, to let the project
maintainers review your contribution.

COPYRIGHT AND LICENSE
---------------------

Copyright (C) 2005-2018 Torsten Schoenfeld <kaffeetisch@gmx.de>

See the LICENSE file in the top-level directory of this distribution for the
full license terms.
