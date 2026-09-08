#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

# The installed frx_abi.h compiles alone, under strict warnings, in a
# consumer that includes the perl headers and then the header from the
# directory the provider config records, and that reaches every entry
# through a NULL-checked table pointer. This is the proof the header
# needs no private include and no vendored copy.

plan skip_all => 'no C compiler configured' unless $Config{cc};
eval { require File::Raw::XML::Install::Files; 1 }
    or plan skip_all => 'File::Raw::XML::Install::Files is not built; run make first';

no warnings 'once';
my $core = $File::Raw::XML::Install::Files::CORE;
plan skip_all => 'the provider config records no directory' unless defined $core && -f "$core/frx_abi.h";

my $dir = tempdir(CLEANUP => 1);
my $src = "$dir/consumer.c";
open my $fh, '>', $src or die "$src: $!";
print {$fh} <<'C';
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "frx_abi.h"

/* every type and every entry, through a table a real consumer would
 * resolve from File::Raw::XML::_abi_ptr at BOOT */
static int
consumer_walk(pTHX_ const frx_abi *A, const char *bytes, STRLEN len)
{
    frx_opts o;
    frx_c14n c;
    frx_doc *d;
    const frx_node *n, *found;
    SV *err = NULL, *text, *canon;
    const char *s, *ns, *local, *value;
    STRLEN slen, nslen, loclen, vlen;
    int count;
    static const char *const ids[] = { "ID" };

    if (!A || A->abi_version < FRX_ABI_VERSION) return 0;
    A->opts_init(&o);
    o.id_attrs = ids;
    o.n_id_attrs = 1;
    d = A->parse(aTHX_ bytes, len, &o, &err);
    if (!d) return 0;
    n = A->root(d);
    if (A->document(d) == NULL || A->kind(n) != FRX_ELEMENT) return 0;
    s = A->ns(n, &slen); s = A->local(n, &slen); s = A->prefix(n, &slen);
    (void)s;
    if (A->parent(n) == NULL) return 0;
    count = A->attr_count(n);
    if (count) A->attr(n, 0, &ns, &nslen, &local, &loclen, &value, &vlen);
    s = A->attr_value(n, NULL, "ID", &slen);
    found = A->find(n, "", "x", NULL);
    found = A->find(n, NULL, "x", found);
    found = A->by_id(d, "ID", "x", 1);
    (void)found;
    if (A->first_child(n)) (void)A->next(A->first_child(n));
    text = A->text(aTHX_ n);
    c.mode = FRX_C14N_EXC; c.comments = 0; c.prefix_list = NULL; c.n_prefix = 0;
    c.without = NULL; c.n_without = 0;
    canon = A->c14n(aTHX_ n, &c);
    if (text) SvREFCNT_dec(text);
    if (canon) SvREFCNT_dec(canon);
    A->doc_free(aTHX_ d);
    return 1;
}

int consumer_entry(pTHX_ IV table);
int consumer_entry(pTHX_ IV table)
{
    const frx_abi *A = table ? INT2PTR(const frx_abi *, table) : NULL;
    return consumer_walk(aTHX_ A, "<r/>", 4);
}
C
close $fh;

# Apple's system perl reports a CORE directory that is present but empty
# on disk; the headers exist only inside the SDK, which MakeMaker reaches
# with -iwithsysroot, and so does this. Check for the file, not the dir.
my $core_inc = -f "$Config{archlibexp}/CORE/EXTERN.h"
    ? "-I$Config{archlibexp}/CORE"
    : qq{-iwithsysroot "$Config{archlibexp}/CORE"};
my $obj = "$dir/consumer$Config{_o}";
my $cmd = join ' ', $Config{cc}, $Config{ccflags}, '-Wall', '-Wextra', '-Werror',
                    "-I$core", $core_inc, '-c', $src, '-o', $obj;
my $out = `$cmd 2>&1`;
my $rc  = $? >> 8;
is($rc, 0, 'the installed frx_abi.h compiles alone in a strict consumer') or diag "$cmd\n$out";
ok(-e $obj, 'and produced an object');

done_testing;
