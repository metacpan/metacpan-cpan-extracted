package Mail::ClamAV;

use 5.006001;
use strict;
use warnings;
use Carp;

our $VERSION;
BEGIN {
    $VERSION = '0.29';
}

# guard against memory errors not being reported
our $Error = (' ' x 255);
$Error = undef;

require Exporter;
use IO::Handle;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# Backwards compatible constants
sub CL_RAW            () { CL_SCAN_RAW() }
sub CL_ARCHIVE        () { CL_SCAN_ARCHIVE() }
sub CL_MAIL           () { CL_SCAN_MAIL() }
sub CL_OLE2           () { CL_SCAN_OLE2() }
sub CL_ENCRYPTED      () { CL_SCAN_BLOCKENCRYPTED() }
sub CL_BLOCKENCRYPTED () { CL_SCAN_BLOCKENCRYPTED() }
sub CL_MAILURL        () { CL_SCAN_MAILURL() }
sub CL_HTML           () { CL_SCAN_HTML() }
sub CL_PE             () { CL_SCAN_PE() }
sub CL_BLOCKBROKEN    () { CL_SCAN_BLOCKBROKEN() }
sub CL_BLOCKMAX       () { CL_SCAN_BLOCKMAX() }

# This allows declaration   use Mail::ClamAV ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( all => [ qw(
    retdbdir

    CL_CLEAN
    CL_VIRUS
    CL_BREAK

    CL_EMAXREC
    CL_EMAXSIZE
    CL_EMAXFILES
    CL_EACCES
    CL_ENULLARG
    CL_ETMPFILE
    CL_EMEM
    CL_EOPEN
    CL_EMALFDB
    CL_ETMPDIR
    CL_ECVD
    CL_EFORMAT

    CL_ENCINIT
    CL_ENCLOAD
    CL_ENCIO

    CL_SCAN_RAW
    CL_SCAN_ARCHIVE
    CL_SCAN_MAIL
    CL_SCAN_OLE2
    CL_SCAN_BLOCKENCRYPTED
    CL_SCAN_HTML
    CL_SCAN_PE
    CL_SCAN_BLOCKBROKEN
    CL_SCAN_MAILURL
    CL_SCAN_BLOCKMAX
    CL_SCAN_ALGORITHMIC
    CL_SCAN_PHISHING_BLOCKSSL

    CL_SCAN_PHISHING_BLOCKCLOAK
    CL_SCAN_ELF

    CL_SCAN_STDOPT

    CL_RAW
    CL_ARCHIVE
    CL_MAIL
    CL_OLE2
    CL_BLOCKENCRYPTED
    CL_HTML
    CL_PE
    CL_BLOCKBROKEN
    CL_MAILURL
    CL_BLOCKMAX
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Mail::ClamAV::constant not defined" if $constname eq 'constant';
    my $val = constant($constname);
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

sub scan {
    my $self = shift;

    my $thing = shift;
    croak "No file argument to scan!" unless defined $thing;

    my $options = shift || 0;

    croak "Invalid number of options to scan()" if @_;

    my ($st, $num_scanned);
    if (
        (UNIVERSAL::isa($thing, 'GLOB')   or
         UNIVERSAL::isa(\$thing, 'GLOB')) and
        defined fileno($thing)
    )
    {
        IO::Handle::flush($thing);
        ($st, $num_scanned) = _scanfd($self, fileno($thing), $options);
    }
    else {
        croak "$thing does not exist" unless -e $thing;
        if (_tainted($thing)) {
            croak "path argument specified to scan() is tainted";
        }
        ($st, $num_scanned) = _scanfile($self, $thing, $options);
    }
    my $status = new Mail::ClamAV::Status;
    $status->error($st);
    $status->errno(0+$st);
    $status->clean($st == CL_CLEAN());
    $status->virus($st == CL_VIRUS());
    if ($status) {
        $status->count($num_scanned);
    }
    else {
        $status->count(0);
    }
    return $status;
}

use Inline C => Config =>
    VERSION  => $VERSION,
    PREFIX   => 'clamav_perl_',
    NAME     => "Mail::ClamAV",
    LIBS     => "-lclamav";
# removed on install
BEGIN {
require "./config.pl";
}
# end removed on install
use Inline C => <<'END_OF_C';
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <clamav.h>


#ifndef CL_ENCINIT
#define CL_ENCINIT 0
#endif
#ifndef CL_ENCLOAD
#define CL_ENCLOAD 0
#endif
#ifndef CL_ENCIO
#define CL_ENCIO 0
#endif
#ifndef CL_DB_NCORE
#define CL_DB_NCORE 0
#endif

#define SvClam(MEM) ((struct clamav_perl *)SvIV(SvRV(MEM)))

static void error(int errcode);

struct clamav_perl {
    struct cl_engine *root;
    struct cl_stat st;
    char is_dir;
    char *path;
    int signatures;
};

SV *clamav_perl_new(char *class, char *path)
{
    SV *self_ref, *self;
    struct stat st;
    struct clamav_perl *c;
    int status;

    Newz(0, c, 1, struct clamav_perl);
    if (stat(path, &st) != 0)
        croak("%s does not exist: %s\n", path, strerror(errno));

    if ((status = cl_init(CL_INIT_DEFAULT)) != CL_SUCCESS) {
        error(status);
        return &PL_sv_undef;
    }
    if (!(c->root = cl_engine_new())) {
        error(status);
        return &PL_sv_undef;
    }

    /* set defaults for limits */
    cl_engine_set_num(c->root, CL_ENGINE_MAX_RECURSION, 5);
    cl_engine_set_num(c->root, CL_ENGINE_MAX_FILES, 1000);
    cl_engine_set_num(c->root, CL_ENGINE_MAX_FILESIZE, 1024 * 1028 * 10); /* 10 Megs */

    status = cl_load(path, c->root, &c->signatures, CL_DB_STDOPT);

    if (status != 0) {
        error(status);
        return &PL_sv_undef;
    }

    /* Bless my structs memory location into the object */
    self_ref = newSViv(0);
    self = newSVrv(self_ref, class);
    sv_setiv(self, (IV) c);
    SvREADONLY_on(self);
    return self_ref;
}

int clamav_perl_statchkdir(SV *self)
{
    int ret;
    struct clamav_perl *c = SvClam(self);
    if (c->is_dir == 0)
        croak("statchkdir() only works if a database directory was specified to new()");
    ret = cl_statchkdir(&c->st);
    cl_statfree(&c->st);
    cl_statinidir(c->path, &c->st);
    return ret;
}

char *clamav_perl_retdbdir()
{
    return (char *)cl_retdbdir();
}

void clamav_perl_buildtrie(SV *self)
{
    struct clamav_perl *c = SvClam(self);
    cl_engine_compile(c->root);
}

int clamav_perl_build(SV *self)
{
    struct clamav_perl *c = SvClam(self);
    int status;
    status = cl_engine_compile(c->root);
    if (status != CL_SUCCESS) {
        cl_engine_free(c->root);
        error(status);
        return 0;
    }
    return 1;
}

int clamav_perl_maxreclevel(SV *self, ...)
{
    Inline_Stack_Vars;
    struct clamav_perl *c = SvClam(self);
    int err = 0;
    long long reclevel = 0;
    if (Inline_Stack_Items > 1) {
        SV *max;
        if (Inline_Stack_Items > 2)
            croak("Invalid number of arguments to maxreclevel()");
        max = Inline_Stack_Item(1);
        cl_engine_set_num(c->root, CL_ENGINE_MAX_RECURSION, SvIV(max));
    }
    reclevel = cl_engine_get_num(c->root, CL_ENGINE_MAX_RECURSION, &err);
    if (err != CL_SUCCESS) {
        error(err);
        return;
    }
    return reclevel;
}

int clamav_perl_maxmailrec(SV *self, ...)
{
    warn("maxmailrec is not longer supported in clamav");
    return 0;
}

int clamav_perl_maxfiles(SV *self, ...)
{
    Inline_Stack_Vars;
    struct clamav_perl *c = SvClam(self);
    int err = 0;
    long long maxfiles = 0;
    if (Inline_Stack_Items > 1) {
        SV *max;
        if (Inline_Stack_Items > 2)
            croak("Invalid number of arguments to maxfiles()");
        max = Inline_Stack_Item(1);
        cl_engine_set_num(c->root, CL_ENGINE_MAX_FILES, SvIV(max));
    }
    maxfiles = cl_engine_get_num(c->root, CL_ENGINE_MAX_FILES, &err);
    if (err != CL_SUCCESS) {
        error(err);
        return;
    }
    return maxfiles;
}

int clamav_perl_maxfilesize(SV *self, ...)
{
    Inline_Stack_Vars;
    struct clamav_perl *c = SvClam(self);
    int err = 0;
    long long maxfsize;
    if (Inline_Stack_Items > 1) {
        SV *max;
        if (Inline_Stack_Items > 2)
            croak("Invalid number of arguments to maxfilesize()");
        max = Inline_Stack_Item(1);
        cl_engine_set_num(c->root, CL_ENGINE_MAX_FILESIZE, SvIV(max));
    }
    maxfsize = cl_engine_get_num(c->root, CL_ENGINE_MAX_FILESIZE, &err);
    if (err != CL_SUCCESS) {
        error(err);
        return;
    }
    return maxfsize;
}

int clamav_perl_maxratio(SV *self, ...)
{
    warn("maxratio is not longer supported in clamav");
    return 0;
}

int clamav_perl_archivememlim(SV *self, ...)
{
    warn("archivememlim is not longer supported in clamav");
    return 0;
}

void DESTROY(SV *self)
{
    struct clamav_perl *c = SvClam(self);
    cl_engine_free(c->root);
    if (c->is_dir == 1)
        cl_statfree(&c->st);
    Safefree(c->path);
    Safefree(c);
}

void clamav_perl__scanfd(SV *self, int fd, int options)
{
    struct clamav_perl *c = SvClam(self);
    STRLEN len;
    int status;
    unsigned long int scanned;
    const char *virname;
    SV *smsg, *sscanned;
    Inline_Stack_Vars;

    Inline_Stack_Reset;

    scanned = 0;
    status = cl_scandesc(fd, &virname, &scanned, c->root, options);
    if (scanned == 0)
        scanned = 1;

    smsg = sv_newmortal();
    sv_setiv(smsg, (IV)status);

    /* virname is some random memory if no virus was found */
    if (status == CL_VIRUS)
        sv_setpv(smsg, virname);
    else if (status == CL_CLEAN)
        sv_setpv(smsg, "Clean");
    else
        sv_setpv(smsg, cl_strerror(status));

    SvIOK_on(smsg);
    Inline_Stack_Push(smsg);
    sscanned = sv_2mortal(newSViv(scanned));
    Inline_Stack_Push(sscanned);
    Inline_Stack_Done;
}

void clamav_perl__scanfile(SV *self, SV *path, int options)
{
    struct clamav_perl *c = SvClam(self);
    STRLEN len;
    int status;
    unsigned long int scanned;
    const char *msg;
    char *p;
    SV *smsg, *sscanned;
    Inline_Stack_Vars;

    Inline_Stack_Reset;

    if (SvTAINTED(path))
        croak("path argument specified to scan() is tainted");

    scanned = 0;
    p = SvPV(path, PL_na);
    status = cl_scanfile(p, &msg, &scanned, c->root, options);
    if (scanned == 0)
        scanned = 1;

    smsg = sv_newmortal();
    sv_setiv(smsg, (IV)status);

    /* msg is some random memory if no virus was found */
    if (status == CL_VIRUS)
        sv_setpv(smsg, msg);
    else if (status == CL_CLEAN)
        sv_setpv(smsg, "Clean");
    else
        sv_setpv(smsg, cl_strerror(status));

    SvIOK_on(smsg);
    Inline_Stack_Push(smsg);
    sscanned = sv_2mortal(newSViv(scanned));
    Inline_Stack_Push(sscanned);
    Inline_Stack_Done;
}

int clamav_perl__tainted(SV *s)
{
    if (SvTAINTED(s))
        return 1;
    else
        return 0;
}

static void error(int errcode)
{
    const char *e;
    SV *err = get_sv("Mail::ClamAV::Error", TRUE);

    sv_setiv(err, (IV)errcode);
    e = cl_strerror(errcode);
    sv_setpv(err, e);
    SvIOK_on(err);
}

int clamav_perl_constant(char *name)
{

/* libclamav specific */
    if (strEQ("CL_CLEAN", name)) return CL_CLEAN;
    if (strEQ("CL_SUCCESS", name)) return CL_SUCCESS;
    if (strEQ("CL_VIRUS", name)) return CL_VIRUS;
    if (strEQ("CL_ENULLARG", name)) return CL_ENULLARG;
    if (strEQ("CL_EARG", name)) return CL_EARG;
    if (strEQ("CL_EMALFDB", name)) return CL_EMALFDB;
    if (strEQ("CL_ECVD", name)) return CL_ECVD;
    if (strEQ("CL_EVERIFY", name)) return CL_EVERIFY;
    if (strEQ("CL_EUNPACK", name)) return CL_EUNPACK;

/* I/O and memory errors */
    if (strEQ("CL_EOPEN", name)) return CL_EOPEN;
    if (strEQ("CL_ECREAT", name)) return CL_ECREAT;
    if (strEQ("CL_EUNLINK", name)) return CL_EUNLINK;
    if (strEQ("CL_ESTAT", name)) return CL_ESTAT;
    if (strEQ("CL_EREAD", name)) return CL_EREAD;
    if (strEQ("CL_ESEEK", name)) return CL_ESEEK;
    if (strEQ("CL_EWRITE", name)) return CL_EWRITE;
    if (strEQ("CL_EDUP", name)) return CL_EDUP;
    if (strEQ("CL_EACCES", name)) return CL_EACCES;
    if (strEQ("CL_ETMPFILE", name)) return CL_ETMPFILE;
    if (strEQ("CL_ETMPDIR", name)) return CL_ETMPDIR;
    if (strEQ("CL_EMAP", name)) return CL_EMAP;
    if (strEQ("CL_EMEM", name)) return CL_EMEM;
    if (strEQ("CL_ETIMEOUT", name)) return CL_ETIMEOUT;

/* internal (not reported outside libclamav) */
    if (strEQ("CL_BREAK", name)) return CL_BREAK;
    if (strEQ("CL_EMAXREC", name)) return CL_EMAXREC;
    if (strEQ("CL_EMAXSIZE", name)) return CL_EMAXSIZE;
    if (strEQ("CL_EMAXFILES", name)) return CL_EMAXFILES;
    if (strEQ("CL_EFORMAT", name)) return CL_EFORMAT;

/* db options */
    if (strEQ("CL_DB_PHISHING", name)) return CL_DB_PHISHING;
    if (strEQ("CL_DB_PHISHING_URLS", name)) return CL_DB_PHISHING_URLS;
    if (strEQ("CL_DB_PUA", name)) return CL_DB_PUA;
    if (strEQ("CL_DB_CVDNOTMP", name)) return CL_DB_CVDNOTMP;
    if (strEQ("CL_DB_OFFICIAL", name)) return CL_DB_OFFICIAL;
    if (strEQ("CL_DB_PUA_MODE", name)) return CL_DB_PUA_MODE;
    if (strEQ("CL_DB_PUA_INCLUDE", name)) return CL_DB_PUA_INCLUDE;
    if (strEQ("CL_DB_PUA_EXCLUDE", name)) return CL_DB_PUA_EXCLUDE;
    if (strEQ("CL_DB_COMPILED", name)) return CL_DB_COMPILED;

/* recommended db settings */
    if (strEQ("CL_DB_STDOPT", name)) return CL_DB_STDOPT;

/* scan options */
    if (strEQ("CL_SCAN_RAW", name)) return CL_SCAN_RAW;
    if (strEQ("CL_SCAN_ARCHIVE", name)) return CL_SCAN_ARCHIVE;
    if (strEQ("CL_SCAN_MAIL", name)) return CL_SCAN_MAIL;
    if (strEQ("CL_SCAN_OLE2", name)) return CL_SCAN_OLE2;
    if (strEQ("CL_SCAN_BLOCKENCRYPTED", name)) return CL_SCAN_BLOCKENCRYPTED;
    if (strEQ("CL_SCAN_HTML", name)) return CL_SCAN_HTML;
    if (strEQ("CL_SCAN_PE", name)) return CL_SCAN_PE;
    if (strEQ("CL_SCAN_BLOCKBROKEN", name)) return CL_SCAN_BLOCKBROKEN;
    if (strEQ("CL_SCAN_MAILURL", name)) return CL_SCAN_MAILURL;
    if (strEQ("CL_SCAN_BLOCKMAX", name)) return CL_SCAN_BLOCKMAX;
    if (strEQ("CL_SCAN_ALGORITHMIC", name)) return CL_SCAN_ALGORITHMIC;
    if (strEQ("CL_SCAN_PHISHING_BLOCKSSL", name)) return CL_SCAN_PHISHING_BLOCKSSL;
    if (strEQ("CL_SCAN_PHISHING_BLOCKCLOAK", name)) return CL_SCAN_PHISHING_BLOCKCLOAK;
    if (strEQ("CL_SCAN_ELF", name)) return CL_SCAN_ELF;
    if (strEQ("CL_SCAN_PDF", name)) return CL_SCAN_PDF;
    if (strEQ("CL_SCAN_STRUCTURED", name)) return CL_SCAN_STRUCTURED;
    if (strEQ("CL_SCAN_STRUCTURED_SSN_NORMAL", name)) return CL_SCAN_STRUCTURED_SSN_NORMAL;
    if (strEQ("CL_SCAN_STRUCTURED_SSN_STRIPPED", name)) return CL_SCAN_STRUCTURED_SSN_STRIPPED;
    if (strEQ("CL_SCAN_PARTIAL_MESSAGE", name)) return CL_SCAN_PARTIAL_MESSAGE;
    if (strEQ("CL_SCAN_HEURISTIC_PRECEDENCE", name)) return CL_SCAN_HEURISTIC_PRECEDENCE;

    if (strEQ("CL_ENGINE_MAX_SCANSIZE", name)) return CL_ENGINE_MAX_SCANSIZE;
    if (strEQ("CL_ENGINE_MAX_FILESIZE", name)) return CL_ENGINE_MAX_FILESIZE;
    if (strEQ("CL_ENGINE_MAX_RECURSION", name)) return CL_ENGINE_MAX_RECURSION;
    if (strEQ("CL_ENGINE_MAX_FILES", name)) return CL_ENGINE_MAX_FILES;
    if (strEQ("CL_ENGINE_MIN_CC_COUNT", name)) return CL_ENGINE_MIN_CC_COUNT;
    if (strEQ("CL_ENGINE_MIN_SSN_COUNT", name)) return CL_ENGINE_MIN_SSN_COUNT;
    if (strEQ("CL_ENGINE_PUA_CATEGORIES", name)) return CL_ENGINE_PUA_CATEGORIES;
    if (strEQ("CL_ENGINE_DB_OPTIONS", name)) return CL_ENGINE_DB_OPTIONS;
    if (strEQ("CL_ENGINE_DB_VERSION", name)) return CL_ENGINE_DB_VERSION;
    if (strEQ("CL_ENGINE_DB_TIME", name)) return CL_ENGINE_DB_TIME;
    if (strEQ("CL_ENGINE_AC_ONLY", name)) return CL_ENGINE_AC_ONLY;
    if (strEQ("CL_ENGINE_AC_MINDEPTH", name)) return CL_ENGINE_AC_MINDEPTH;
    if (strEQ("CL_ENGINE_AC_MAXDEPTH", name)) return CL_ENGINE_AC_MAXDEPTH;
    if (strEQ("CL_ENGINE_TMPDIR", name)) return CL_ENGINE_TMPDIR;
    if (strEQ("CL_ENGINE_KEEPTMP", name)) return CL_ENGINE_KEEPTMP;

    if (strEQ("CL_ENCINIT", name)) return CL_ENCINIT;
    if (strEQ("CL_ENCLOAD", name)) return CL_ENCLOAD;
    if (strEQ("CL_ENCIO", name)) return CL_ENCIO;

    if (strEQ("CL_SCAN_STDOPT", name)) return CL_SCAN_STDOPT;

    croak("Invalid function %s", name);
}

END_OF_C

# For the return status of scan
package Mail::ClamAV::Status;
use strict;

use Class::Struct;

import Mail::ClamAV qw(CL_CLEAN CL_VIRUS);

use overload
    '""'   => sub { $_[0]->error },
    '+'    => sub { $_[0]->errno },
    'cmp'  => sub { $_[2] ? $_[1] cmp "$_[0]" : "$_[0]" cmp $_[1] },
    'bool' => sub {
        $_[0]->errno == CL_CLEAN() or
        $_[0]->errno == CL_VIRUS()
    };

struct(
    'Mail::ClamAV::Status' => {
        errno  => '$',
        clean  => '$',
        virus  => '$',
        error  => '$',
        count  => '$'
    }
);

1;
__END__

=head1 NAME

Mail::ClamAV - Perl extension for the clamav virus scanner

=head1 SYNOPSIS

    use Mail::ClamAV qw/:all/;


    # $Mail::ClamAV::Error in numeric context return clamav's
    # error status code which corresponds to the constants which
    # can be exported
    my $c = new Mail::ClamAV("/path/to/directory/or/file")
        or die "Failed to load db: $Mail::ClamAV::Error (", 0+$Mail::;

    # You can get retdbdir() to get the database dir in
    # clamav's conf
    my $c = new Mail::ClamAV(retdbdir())
        or die "Failed to load db: $Mail::ClamAV::Error";

    # When database is loaded, you must create the proper trie with:
    $c->build or die "Failed to build engine: $Mail::ClamAV::Error";

    # check to see if we need to reload
    if ($c->statchkdir) {
        $c = new Mail::ClamAV(retdbdir());
        $c->build or die "Failed to build engine: $Mail::ClamAV::Error";
    }

    # Set some limits (only applies to scan())
    $c->maxreclevel(4);
    $c->maxfiles(20);
    $c->maxfilesize(1024 * 1024 * 20); # 20 megs

    # Scan a filehandle (scandesc in clamav)
    # scan(FileHandle or path, Bitfield of options)
    my $status = $c->scan(FH, CL_SCAN_ARCHIVE|CL_SCAN_MAIL);

    # Scan a file (scanfile in clamav)
    my $status = $c->scan("/path/to/file.eml", CL_SCAN_MAIL);

    # $status is an overloaded object
    die "Failed to scan: $status" unless $status;
    if ($status->virus) {
        print "Message is a virus: $status\n";
    }
    else {
        print "No virus found!\n";
    }


=head1 DESCRIPTION

Clam AntiVirus is an anti-virus toolkit for UNIX
L<http://www.clamav.com/>.  This module provide a simple interface to
its C API.

=head2 EXPORT

None by default.

=head2 Exportable constants

Options for scanning.

=over 1


=item CL_SCAN_STDOPT

This is an alias for a recommended set of scan options. You should use it to
make your software ready for new features in the future versions of libclamav. 

=item CL_SCAN_RAW

Use it alone if you want to disable support for special files. 

=item CL_SCAN_ARCHIVE

This flag enables transparent scanning of various archive formats. 

=item CL_SCAN_BLOCKENCRYPTED

With this flag the library will mark encrypted archives as viruses
(Encrypted.Zip, Encrypted.RAR). 

=item CL_SCAN_BLOCKMAX

Mark archives as viruses if maxfiles, maxfilesize, or maxreclevel limit is
reached. 

=item CL_SCAN_MAIL

Enable support for mail files. 

=item CL_SCAN_MAILURL

The mail scanner will download and scan URLs listed in a mail body. This flag
should not be used on loaded servers. Due to potential problems please do not
enable it by default but make it optional. 

=item CL_SCAN_OLE2

Enables support for OLE2 containers (used by MS Office and .msi files). 

=item CL_SCAN_PE

This flag enables deep scanning of Portable Executable files and allows
libclamav to unpack executables compressed with run-time unpackers. 

=item CL_SCAN_ELF

Enable support for ELF files. 

=item CL_SCAN_BLOCKBROKEN

libclamav will try to detect broken executables and mark them as
Broken.Executable. 

=item CL_SCAN_HTML

This flag enables HTML normalisation (including ScrEnc decryption). 

=item CL_SCAN_ALGORITHMIC

Enable algorithmic detection of viruses. 

=item CL_SCAN_PHISHING_DOMAINLIST

With a minor version bump clamav development team removed this and broke backwards compatibility,
so it is no longer supported in this module as of 0.22.

=item CL_SCAN_PHISHING_BLOCKSSL

Phishing module: always block SSL mismatches in URLs. 

=item CL_SCAN_PHISHING_BLOCKCLOAK

Phishing module: always block cloaked URLs. 

=back

Status returns. You can get the status code by putting the status object
returned into into numeric context.

    my $status = $c->scan("foo.txt");
    print "Status: ", ($status + 0), "\n";


The following are returned statuses if no error occured.


=over 1

=item CL_CLEAN

no viruses found

=item CL_VIRUS

virus found, put the status in scalar context to see the type

=back

Error statuses

=over 1

=item CL_EMAXREC

recursion limit exceeded 

=item CL_EMAXSIZE

size limit exceeded 

=item CL_EMAXFILES

files limit exceeded 

=item CL_EACCES

access denied 

=item CL_ENULLARG

null argument 

=item CL_ETMPFILE

tmpfile() failed 

=item CL_EMEM

memory allocation error 

=item CL_EOPEN

file open error 

=item CL_EMALFDB

malformed database 

=item CL_ETMPDIR

mkdir() failed 

=item CL_ECVD

not a CVD file (or broken) 

=item CL_EFORMAT

bad format or broken file 

=item CL_ENCINIT

NodalCore initialization failed 

=item CL_ENCLOAD

error loading NodalCore database 

=item CL_ENCIO

general NodalCore I/O error 

=back

=head2 Exportable functions

These function can be exported either individually or using the :all export
flags

=over 1

=item retdbdir

This function returns the path to the database directory specified when clamav
was compiled.

=back

=head1 METHODS

=head2 Settings

NOTE
These settings only apply to C<scan()> and archives (CL_SCAN_ARCHIVE).

=over 1

=item maxreclevel

Sets the maximum recursion level into archives [default 5].

=item maxmailrec

With a minor version bump clamav development team removed this and broke backwards compatibility,
so it is no longer supported in this module as of 0.22.

=item maxfiles

Maximum number of files that will be scanned [default 1000]. A value of zero
disables the check.

=item maxfilesize

Maximum file size that will be scanned in bytes [default 10M]. A value of zero
disables the check.

=item maxratio

With a minor version bump clamav development team removed this and broke backwards compatibility,
so it is no longer supported in this module as of 0.22.

=back

=head2 Scanning

All of these methods return a status object. This object is overloaded to make
things cleaner. In boolean context this will return false if there was an
error.  For example:
    my $status = $c->scan("foo.txt");
    die "Error scanning: $status" unless $status;

As you probably just noticed, $status in scalar context returns the error
message. In addition to the overloading you just saw, $status has the
following methods:

=over 1

=item errno

The numeric value (if any) clamav returned.

=item clean

This will be true if the message was not a virus and an error did not occur.

=item virus

Returns true if the message is a virus.

=item error

Return the error message (if any). This is the same thing as quoting $status.

=item count

Returns the number of messages scanned. Only works with archives.

=back

=over 1

=item scan(FileHandle or Path, Bitfield of options)

C<scan()> takes a FileHanle or path and passed the file descriptor for that off
to clamav.  The second argument is a bitfield of options, CL_SCAN_MAIL,
CL_SCAN_ARCHIVE or CL_SCAN_RAW L<"Exportable constants">.

This function returns the status object discussed earlier.

Note that if you are running in taint mode (-T) and a tainted path is passed to
C<scan()>, it will C<croak()>.

=item scanbuff($buff)

This function was taken out of ClamAV in 0.90 and was thus taken out of
Mail::ClamAV.

=back

=head2 Data Directory stats

If the path passed into C<new()> is a directory Mail::ClamAV will set things up
to check for updated database files. Calling the C<statchkdir()> will check the
database directory to the stats we have in memory. If anything has changed true
is returned, otherwise false.

NOTE: trying to use C<statchkdir()> when you passed in a database file instead
of directory will produce a fatal error.

C<statchkdir()> is useful for long running daemons that need to check to see if
it is time to reload the database. Reloading is simply getting a new
Mail::ClamAV object and initializing it.

=head1 SEE ALSO

The ClamAV API documentation L<http://www.clamav.net/doc/html-0.65/node44.html>

=head1 AUTHOR

David P.C. Wollmann E<lt>converter42@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Gossamer Threads Inc. L<http://www.gossamer-threads.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

