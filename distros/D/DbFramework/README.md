DbFramework
===========


Description
-----------

DbFramework is a collection of classes for manipulating DBI databases.
The classes are loosely based on the CDIF Data Model Subject Area.

*Note*: Do not use DbFramework.  I believe it is outdated and not working
anymore.  I obtained its ownership only to keep it clean until it is
retired.  If you were using DbFramework, consider other, more recent
solutions like XML instead.

The last release 1.10 of DbFramework is due 1999/5/13, even before Perl
5.005_03.  As today is 2008/4/19, that is *NINE* years ago.  It is not
surprising DbFramework does not work now.  If you are still using CDIF
Data Model Subject Area, it might be easier to migrate your code to use
XML, than to make DbFramework working.  Besides, DbFramework takes
a CPAN root namespace, DbFramework::*, which is not right, too.

DbFramework was written by Paul Sharpe (paul@miraclefish.com, CPAN ID:
`PSHARPE`).  If you are looking for older versions, see Paul's BackPen
directory: http://backpan.perl.org/authors/id/P/PS/PSHARPE/

The original `README` follows.


The Original `README`
---------------------

    DbFramework is a collection of classes for manipulating DBI databases.
    The classes are loosely based on the CDIF Data Model Subject Area.
    
    This module will help you to
    
      - Present data model objects (tables, columns) as HTML
      - Add persistency to your Perl objects
      - Manipulate DBI databases through an HTML forms interface
    
    See the POD for further details.
    
    Prerequisites
    =============
    
      Perl 5.005
      Alias
      CGI
      URI::Escape
      DBI 1.06
      Text::FillIn
      Term::ReadKey
    
    DbFramework has been successfully built and tested on (at least) the
    following configurations.  In general the driver version is VERY
    IMPORTANT as DbFramework makes use of some of the newer DBI metadata
    methods which may only be implemented in development branches of
    certain drivers.
    
      OS               Driver                     Database
      ================ ========================== ===================
      RedHat Linux 5.1 Msql-Mysql-modules-1.21_15 Mysql 3.22.14-gamma
                       Msql-Mysql-modules-1.21_15 Msql 2.0.8
                       DBD-Pg-0.91                PostgreSQL 6.4.2
    
    Note that DBD::CSV is unlikely to be supported in the near future due
    to the limitations of this driver.
    
    Installation
    ============
    
      1) Ensure you have installed the prerequisites above.
    
      2)  perl Makefile.PL
        Select each DBD driver you wish to test DbFramework against.
          make
          make test
        You will need permission to create the databases 'dbframework_test'
        and 'dbframework_catalog' for each DBI driver you chose to test.
          make install
    
    To use forms/dbforms.cgi, install it in a CGI directory then 'perldoc
    forms/dbforms.cgi'.
    
    paul@miraclefish.com


Download
--------

DbFramework is hosted is on…

* [DbFramework on GitHub]

* [DbFramework on MetaCPAN]

[DbFramework on GitHub]: https://github.com/imacat/DbFramework
[DbFramework on MetaCPAN]: https://metacpan.org/release/DbFramework


Support
-------

The DbFramework project is hosted on GitHub.  Address your
issues on the GitHub issue tracker
https://github.com/imacat/DbFramework/issues.

If you are still using it and want to take over this project, file an
issue request on GitHub.  Thank you.

Authors
-------

Version since 1.11 maintained by [imacat].

Version 1.10 and earlier written by [Paul Sharpe].

[imacat]: mailto:imacat@mail.imacat.idv.tw
[Paul Sharpe]: mailto:paul@miraclefish.com


To Do
-----

* Moved the test tables creation from `Makefile.PL`/`Build.PL` to the
  test suite, and clean up the test tables after the test suite
  finished.
* Remove the `Makefile.PL`/`Build.PL` dependency to DbFramework::Util,
  and hence Term::ReadKey.  It does not make sense that
  `Makefile.PL`/`Build.PL` fails to run.  CPAN and CPANPLUS shells
  cannot install with this, too.
* Rename `t/util.pl` to `t/util.pm`, and remove `Makefile.PL/Build.PL`
  dependency to it, too.
* Dealing with the installation of `forms/dbforms.cgi`.
* Register a proper name space and drop the unused.
* Transfer the primary maintainer of DbFramework::CandidateKey,
  DbFramework::Catalog, DbFramework::DataModelObject,
  DbFramework::DataType::ANSII, DbFramework::DataType::Mysql,
  DbFramework::DefinitionObject, DbFramework::Relationship and
  DbFramework::Template to me.
* Remove "UNAUTHORIZED RELEASE" from Meta CPAN.
* Maybe make DbFramework working again.
* Retire DbFramework.


Copyright
---------

    Copyright (c) 1998-1999 Paul Sharpe, 2008-2021 imacat.  All rights
    reserved.  This program is free software; you can redistribute it
    and/or modify it under the same terms as Perl itself.
