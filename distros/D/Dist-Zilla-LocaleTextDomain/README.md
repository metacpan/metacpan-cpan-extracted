Dist/Zilla/LocaleTextDomain version 0.90
========================================

Dist::Zilla::LocaleTextDomain provides tools to scan your Perl libraries for
[Local::TextDomain](http://metacpan.org/module/Locale::TextDomain)-style
localizable strings, create a language template, and initialize translation
files and keep them up-to-date. If you use
[Local::TextDomain](http://metacpan.org/module/Locale::TextDomain) and
[Dist::Zilla](http://dzil.org/), you need this module!

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

This module requires the the [gettext](http://www.gnu.org/software/gettext/)
utilities. It also requires the following non-core modules:

* Dist::Zilla
* Dist::Zilla::File::FromCode
* Dist::Zilla::Role::FileGatherer
* Email::Address
* Encode
* File::Find::Rule
* IPC::Cmd
* IPC::Run3
* Locale::Codes::Country
* Locale::Codes::Language
* Moose
* Moose::Role:
* Moose::Util::TypeConstraints
* MooseX::Types::Path::Class
* Path::Class
* namespace::autoclean

Copyright and License
---------------------

This software is copyright (c) 2012-2013 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
