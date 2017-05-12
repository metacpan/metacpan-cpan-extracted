    README for DiaColloDB

ABSTRACT
    DiaColloDB - diachronic collocation database

REQUIREMENTS
  Perl Modules
    The following non-core perl modules are required, and should be
    available from CPAN <http://www.cpan.org>.

    DDC::Concordance (formerly ddc-perl)
        Perl module for DDC client connections. Available from CPAN, or via
        SVN from
        <https://svn.code.sf.net/p/ddc-concordance/code/ddc-perl/trunk>

    DDC::XS (formerly ddc-perl-xs)
        XS wrappers for DDC query parsing. Available from CPAN, or via SVN
        from
        <https://svn.code.sf.net/p/ddc-concordance/code/ddc-perl-xs/trunk>

    File::Map
    File::Temp
    JSON
    IPC::Run
    Log::Log4perl
    LWP::UserAgent
        For querying external servers via DiaColloDB::Client::http.

    PDL (optional)

        Perl Data Language for fast fixed-size numeric data structures, used
        by the TDF (term-document frequency matrix) relation type. It should
        still be possible to build, install, and run the DiaColloDB
        distribution on a system without PDL installed, but use of the the
        TDF (term x document) matrix relation type will be disabled.

    PDL::CCS
        (optional)

        PDL module for sparse index-encoded matrices, used by the TDF
        (term-document frequency matrix) relation type. See the caveats
        under PDL.

    Tie::File::Indexed
        For handling large (temporary) arrays during index creation.

    XML::LibXML
        (optional)

        Required for index compilation from TCF or TEI corpus sources.

  Additional Requirements
    In order to make use of this module, you will also need either a corpus
    to index or an existing index to query. See "SUBCLASSES" in
    DiaColloDB::Document for a list of supported corpus input formats.

DESCRIPTION
    The DiaColloDB package provides a set of object-oriented Perl modules
    and a command-line utility suite for constructing and querying native
    diachronic collocation indices with optional inclusion of a DDC server
    back-end for fine-grained queries.

INSTALLATION
    Issue the following commands to the shell:

     bash$ cd DiaColloDB-0.01 # (or wherever you unpacked this distribution)
     bash$ perl Makefile.PL   # check requirements, etc.
     bash$ make               # build the module
     bash$ make test          # (optional): test module before installing
     bash$ make install       # install the module on your system

    See perlmodinstall for details.

USAGE
    Assuming you have a raw text corpus you'd like to access via this
    module, the following steps will be required:

  Corpus Annotation and Conversion
    Your corpus must be tokenized and annotated with whatever word-level
    attributes and/or document-level metadata you wish to be able to query;
    in particular document date is required. See "SUBCLASSES" in
    DiaColloDB::Document for a list of currently supported corpus formats.

  DiaCollo Index Creation
    You will need to compile a DiaColloDB index for your corpus. This can be
    accomplished using the dcdb-create.perl(1) script from this
    distribution.

  Command-Line Queries
    Once you have compiled a local index, you can query it from the
    command-line using the dcdb-query.perl(1) script from this distribution.

  (Optional) WWW Wrappers
    If you want online visualization of a local index, consider installing
    the DiaColloDB::WWW distribution (available on CPAN) and following the
    instructions in its README.txt file.

SEE ALSO
    *   The DiaColloDB module documentation describes the API of the
        underlying perl module; when in doubt, look here.

    *   The dcdb-create.perl(1) script can be used to create a DiaColloDB
        index for a corpus in one of the supported corpus formats.

    *   The dcdb-query.perl(1) script can execute runtime queries over a
        local DiaColloDB index or a remote web-service via the
        DiaColloDB::Client interface.

    *   <http://kaskade.dwds.de/dstar/dta/diacollo/> contains a live
        web-service wrapper for a DiaCollo index over the *Deutsches
        Textarchiv* corpus of historical German, including a user-oriented
        help page (in English).

    *   The DiaColloDB::WWW distribution contains scripts and utilities for
        creating HTTP-based web-services for local DiaCollo indices,
        including various online visualizations.

    *   The CLARIN-D DiaCollo Showcase at
        <http://clarin-d.de/de/kollokationsanalyse-in-diachroner-perspektive
        > contains a brief example-driven tutorial on using the web-services
        provided by the DiaColloDB::WWW distribution (in German).

AUTHOR
    Bryan Jurish <moocow@cpan.org>

