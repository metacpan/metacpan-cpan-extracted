Locale::Maketext::Gettext - Joins the gettext and Maketext frameworks
=====================================================================

Locale::Maketext::Gettext joins the [GNU gettext] and [Maketext]
frameworks.  It is a subclass of Locale::Maketext that follows the
way GNU gettext works.  It works seamlessly, both in the sense of
GNU gettext and Maketext.  As a result, you enjoy both their
advantages, and get rid of both their problems, too.

You start as a usual GNU gettext localization project:  Work on
PO files with the help of translators, reviewers and Emacs.  Turn
them into MO files with `msgfmt`.  Copy them into the appropriate
locale directory, such as
`/usr/share/locale/de/LC_MESSAGES/myapp.mo`.

Then, build your Maketext localization class, with your base class
changed from Locale::Maketext to Locale::Maketext::Gettext.  That's
all. ^_*'

[GNU gettext]: https://www.gnu.org/software/gettext/
[Maketext]: https://perldoc.perl.org/Locale::Maketext


Locale::Maketext::Gettext::Functions
------------------------------------

Locale::Maketext::Gettext::Functions is a functional
interface to Locale::Maketext::Gettext (and Locale::Maketext).
It works completely the GNU gettext way.  It plays magic to
Locale::Maketext.  No more localization class/subclasses and language
handles are required.


The `maketext` script
---------------------

The `maketext` script is a command-line interface to
Locale::Maketext::Gettext (and Locale::Maketext).  It can be used in
shell scripts, etc, to translate, maketext and return the
result.  It enables Maketext to be integrated into other programming
languages/systems, like bash/csh, python, PHP, C, etc.  It works
like the command-line program `gettext`.


System Requirements
-------------------

1. Perl, version 5.8.0 or above.  Locale::Maketext::Gettext uses the
   utf8 text internally that is only available since 5.8.0.  You can
   run `perl -v` to see your current Perl version.  If you don't have
   Perl, or if you have an older version of Perl, you can download and
   install/upgrade it from the [Perl website].  If you are using
   MS-Windows, you can download and install [ActiveState ActivePerl].

2. Required Perl modules: None.

3. Optional Perl modules: None.

[Perl website]: https://www.perl.org
[ActiveState ActivePerl]: https://www.activestate.com


Download
--------

Locale::Maketext::Gettext is hosted is on…

* [Locale-Maketext-Gettext on GitHub]

* [Locale-Maketext-Gettext on MetaCPAN]

[Locale-Maketext-Gettext on GitHub]: https://github.com/imacat/Locale-Maketext-Gettext
[Locale-Maketext-Gettext on MetaCPAN]: https://metacpan.org/release/Locale-Maketext-Gettext


Install
-------

### Install with [ExtUtils::MakeMaker]

Locale-Maketext-Gettext uses standard Perl installation with
ExtUtils::MakeMaker.  Follow these steps:

    % perl Makefile.PL
    % make
    % make test
    % make install

When running `make install`, make sure you have the privilege to write
to the installation location.  This usually requires the `root`
privilege.

If you are using ActivePerl under MS-Windows, you should use `nmake`
instead of `make`.  [nmake can be obtained from the Microsoft FTP site.]

If you want to install into another location, you can set the
`PREFIX`.  For example, to install into your home when you are not
`root`:

    % perl Makefile.PL PREFIX=/home/jessica

Refer to the documentation of ExtUtils::MakeMaker for more
installation options (by running `perldoc ExtUtils::MakeMaker`).


### Install with [Module::Build]

You can install with Module::Build instead, if you prefer.  Follow
these steps:

    % perl Build.PL
    % ./Build
    % ./Build test
    % ./Build install

When running `./Build install`, make sure you have the privilege to
write to the installation location.  This usually requires the `root`
privilege.

If you want to install into another location, you can set the
`--prefix`.  For example, to install into your home when you are not
``root``:

    % perl Build.PL --prefix=/home/jessica

Refer to the documentation of Module::Build for more
installation options (by running `perldoc Module::Build`).


### Install with the CPAN Shell

You can install with the CPAN shell, if you prefer.  CPAN shell
takes care of ExtUtils::MakeMaker and Module::Build for you:

    % cpan Locale::Maketext::Gettext

Make sure you have the privilege to write to the installation
location.  This usually requires the `root` privilege.  Since CPAN
shell 1.81 you can set `make_install_make_command` and
`mbuild_install_build_command` in your CPAN configuration to switch
to `root` just before install:

    % cpan
    cpan> o conf make_install_make_command "sudo make"
    cpan> o conf mbuild_install_build_command "sudo ./Build"
    cpan> install Locale::Maketext::Gettext

If you want to install into another location, you can set `makepl_arg`
and `mbuild_arg` in your CPAN configuration.  For example, to install
into your home when you are not `root`:

    % cpan
    cpan> o conf makepl_arg "PREFIX=/home/jessica"
    cpan> o conf mbuild_arg "--prefix=/home/jessica"
    cpan> install Locale::Maketext::Gettext

Refer to the documentation of cpan for more CPAN shell commands
(by running `perldoc cpan`).


### Install with the CPANPLUS Shell

You can install with the CPANPLUS shell, if you prefer.  CPANPLUS
shell takes care of ExtUtils::MakeMaker and Module::Build for you:

    % cpanp -i Locale::Maketext::Gettext

Make sure you have the privilege to write to the installation
location.  This usually requires the `root` privilege.

If you want to install into another location, you can set
`makemakerflags` and `buildflags` in your CPANPLUS configuration.
For example, to install into your home when you are not `root`:

    % cpanp
    CPAN Terminal> s conf makemakerflags "PREFIX=/home/jessica"
    CPAN Terminal> s conf buildflags "--prefix=/home/jessica"
    CPAN Terminal> install Locale::Maketext::Gettext

Refer to the documentation of `cpanp` for more CPANPLUS shell
commands (by running `perldoc cpanp`).

[ExtUtils::MakeMaker]: https://metacpan.org/release/ExtUtils-MakeMaker
[nmake can be obtained from the Microsoft FTP site.]: ftp://ftp.microsoft.com/Softlib/MSLFILES/nmake15.exe
[Module::Build]: https://metacpan.org/release/Module-Build


Source
------

Source is now on Github.  See
https://github.com/imacat/Locale-Maketext-Gettext.


Support
-------

The Locale-Maketext-Gettext project is hosted on GitHub.  Address your
issues on the GitHub issue tracker
https://github.com/imacat/Locale-Maketext-Gettext/issues.


News, Changes and Updates
-------------------------

Refer to the Changes for changes, bug fixes, updates, new functions, etc.


Thanks
------

* Thanks to [Max Maischein] for reporting CPAN tester failures 200029,
  200332 and 200331, that helps me find the shell character escape
  problem on my test suite.

* Thanks to [Andreas Koenig] for reporting CPAN tester failures 387357
  and submitting [rt bug 23956], informing me the base class
  Locale::Maketext has updated its error handling behavior in the Perl
  5.9.

* Thanks to [Chris Travers] for suggestion to implement `pgettext()`
  in GNU gettext as `pmaketext()`.

[Max Maischein]: mailto:corion@corion.net
[Andreas Koenig]: mailto:andk@cpan.org
[rt bug 23956]: https://rt.cpan.org/Public/Bug/Display.html?id=23956
[Chris Travers]: mailto:chris.travers@gmail.com


To Do
-----

* Design a way to install the MO file through ExtUtils::MakeMaker and
  Module::Build.


Copyright
---------

    Copyright (c) 2003-2021 imacat. All rights reserved. This program is free
    software; you can redistribute it and/or modify it under the same terms
    as Perl itself.
