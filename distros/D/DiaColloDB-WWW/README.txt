    README for DiaColloDB::WWW

ABSTRACT
    DiaColloDB::WWW - www wrapper scripts and utitilties for DiaColloDB
    diachronic collocation database

REQUIREMENTS
  Perl Modules
    The following non-core perl modules are required, and should be
    available from CPAN <http://www.cpan.org>.

    DiaColloDB
    File::Copy::Recursive
    File::ShareDir
    File::ShareDir::Install
    File::chmod::Recursive
    HTTP::Daemon
    HTTP::Message
    MIME::Types
    Template
    URI
    URI::Escape

  Additional Requirements
    In order to make use of this module, you will also need an existing
    DiaCollo index to query. See dcdb-create.perl(1) from the DiaColloDB
    distribution for details.

DESCRIPTION
    The DiaColloDB::WWW package provides a set of Perl modules and wrapper
    scripts implementing a simple webservice API for DiaColloDB indices,
    including a simple user interface and online visualization.

INSTALLATION
    Issue the following commands to the shell:

     bash$ cd DiaColloDB-WWW-0.01 # (or wherever you unpacked this distribution)
     bash$ perl Makefile.PL       # check requirements, etc.
     bash$ make                   # build the module
     bash$ make test              # (optional): test module before installing
     bash$ make install           # install the module on your system

    See perlmodinstall for details.

USAGE
    Assuming you have a raw text corpus you would like to access via this
    module, the following steps will be required:

  Corpus Annotation and Conversion
    Your corpus must be tokenized and annotated with whatever word-level
    attributes and/or document-level metadata you wish to be able to query;
    in particular document date is required. See "SUBCLASSES" in
    DiaColloDB::Document for a list of currently supported corpus formats.

  DiaCollo Index Creation
    You will need to compile a DiaColloDB index for your corpus. This can be
    accomplished using the dcdb-create.perl(1) script from the DiaColloDB
    distribution.

  WWW Wrappers
    The proper domain of this distribution is to mediate between a
    high-level user interface running in a web browser and the DiaColloDB
    index API itself. Utilities are provided for accomplishing this task in
    the following two ways:

   ... as a Standalone Server
    Once you have a DiaCollo index, you can access it by running the
    standalone server script dcdb-www-server.perl(1) included in this
    distribution.

   ... or via an External HTTP Server
    Alternately, you can use the dcdb-www-create.perl(1) script from this
    distribution to bootstrap a wrapper directory for use with an external
    webserver such as apache <http://httpd.apache.org/>. You will need to
    manually configure your webserver for the directory thus created.

    In either case, additional configuration will be necessary if you wish
    to have access to the corpus KWIC-link function, which requires a
    running DDC Server <http://sourceforge.net/projects/ddc-concordance/>
    and corresponding web wrappers for corpus searching.

SEE ALSO
    *   The user help page for the DiaColloDB::WWW wrappers at
        <http://kaskade.dwds.de/diacollo/help.perl>.

    *   The CLARIN-D DiaCollo Showcase at
        <http://clarin-d.de/de/kollokationsanalyse-in-diachroner-perspektive
        > contains a brief example-driven tutorial on using the web-service
        implemented by the DiaColloDB::WWW wrappers (in German).

    *   The DiaColloDB::WWW and DiaColloDB documentation.

THIRD PARTY LIBRARIES
    Includes d3.layout.cloud.js by Jason Davies, see
    <https://github.com/jasondavies/d3-cloud> for details.

    Includes purl.js by Mark Perkins, see
    <https://github.com/allmarkedup/purl> for details.

    Online time-series visualization via the "highcharts" format dynamically
    loads client-side JavaScript libraries not included in this distribution
    from <http://www.highcharts.com/>. The Highcharts JavaScript libraries
    are available free of cost for non-commercial use; see
    <http://www.highcharts.com/products/highcharts/#non-commercial> for
    details.

AUTHOR
    Bryan Jurish <moocow@cpan.org> wrote and maintains the DiaColloDB::WWW
    distribution.

