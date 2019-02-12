    README for GermaNet::Flat

ABSTRACT
    GermaNet::Flat - Simple flat interface to GermaNet (and other) thesaurus
    relations

REQUIREMENTS
    Perl Modules
        See "Makefile.PL", "META.json", and/or "META.yml" in the
        distribution directory. Perl dependencies should be available on
        CPAN <http://metacpan.org>.

    HTTP Server
        If you wish to use the included "gn-view.perl" CGI script to provide
        a browser-based exploratory interface, you will need a local HTTP
        server (e.g. apache) to handle the dirty work. See your HTTP
        server's documentation for details on how to configure CGI wrappers.

DESCRIPTION
    The "GermaNet::Flat" package provides a simple object-oriented API for
    "flat" access to GermaNet <http://www.sfs.uni-tuebingen.de/GermaNet/>
    (and other) thesaurus relations. It supports compilation of GermaNet XML
    sources to Berkeley DB using the DB_File module, CDB using the CDB_File
    module, native perl HASH-refs using the Storable module, or
    dictionary-like plain text.

INSTALLATION
    Issue the following commands to the shell:

     bash$ cd GermaNet-Flat-0.01  # (or wherever you unpacked this distribution)
     bash$ perl Makefile.PL       # check requirements, etc.
     bash$ make                   # build the module
     bash$ make test              # (optional): test module before installing
     bash$ make install           # install the module on your system

AUTHOR
    Bryan Jurish <moocow@cpan.org>

COPYRIGHT AND LICENSE
    Copyright (C) 2013-2019 by Bryan Jurish

    This package is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself, either Perl version 5.24.1 or, at
    your option, any later version of Perl 5 you may have available.

SEE ALSO
    <http://www.sfs.uni-tuebingen.de/GermaNet/>,
    <https://code.google.com/p/perlapi4germanet>, perl(1), ...

