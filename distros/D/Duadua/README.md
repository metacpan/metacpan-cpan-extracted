# Duadua

This is Perl module `Duadua`.

<a href="https://github.com/bayashi/Duadua/blob/main/lib/Duadua.pm"><img src="https://img.shields.io/badge/Version-0.34-green?style=flat"></a> <a href="https://github.com/bayashi/Duadua/blob/main/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png?style=flat"></a> <a href="https://github.com/bayashi/Duadua/actions"><img src="https://github.com/bayashi/Duadua/workflows/main/badge.svg?_t=1720941083"/></a> <a href="https://coveralls.io/r/bayashi/Duadua"><img src="https://coveralls.io/repos/bayashi/Duadua/badge.png?_t=1720941083&branch=main"/></a>

`Duadua` is a User-Agent detector.

* Detect over 160 User-Agents
    * Browsers, Bots and CLI clients
* Detect name, OS and version
* Optimized performance for recent actual logs on a Web site

Send an issue or PR on Github to add a User-Agent you want to detect if it's not supported.

## INSTALLATION

### cpanm

`Duadua` installation is straightforward. If your `cpanm` command is set up,
you should just be able to do

    % cpanm Duadua

### download

Download it or git clone it, then build it as per the usual:

    $ git clone git@github.com:bayashi/Duadua.git
    $ cd Duadua
    $ perl Makefile.PL
    $ make && make test

Then install it:

    % make install


## DOCUMENTATION

`Duadua` documentation is available as in POD. So you can do:

    % perldoc Duadua


## REPOSITORY

Duadua is hosted on github: http://github.com/bayashi/Duadua


## LICENSE

`Duadua` is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.


## AUTHOR

Dai Okabayashi bayashi@cpan.org
