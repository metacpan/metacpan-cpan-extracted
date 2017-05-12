package Dist::Maker::Template::XS;
use utf8;
use Mouse;
use MouseX::StrictConstructor;

extends 'Dist::Maker::Template::Default';
with    'Dist::Maker::Template';

sub distribution {
    return <<'DIST';
: cascade Default;

:# @@ Makefile.PL

: after author_requires -> {
        Module::Install::XSUtil 0.41
: }

: after mpl_command {
use_xshelper;
cc_warnings;
cc_src_paths 'src';
: }

:# @@ author/requires.cpanm
: after author_requires_cpanm_configure_requires -> {
Module::Install::XSUtil
: }

: after author_requires_cpanm_test_requires -> {
Test::LeakTrace
Test::Valgrind
: }

:# @@ .gitignore
: after gitignore {
src/*.c
: }
:# @@ MANIFEST.SKIP
: after manifest_skip {
src/.*\.c$
: }
:# @@ lib/$dist.module_path
: after module_code -> {
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);
: }

: override basic_t_tests -> {
is <: $dist.module :>::hello(), 'Hello, world!';
: }

: after extra_files -> {
@@ src/<: $dist :>.xs
#define NEED_newSVpvn_flags
#include "xshelper.h"

#define MY_CXT_KEY "<: $dist.module :>::_guts" XS_VERSION
typedef struct {
} my_cxt_t;
START_MY_CXT

static void
my_cxt_initialize(pTHX_ pMY_CXT) {
}

MODULE = <: $dist.module :>    PACKAGE = <: $dist.module :>

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    my_cxt_initialize(aTHX_ aMY_CXT);
}

#ifdef USE_ITHREADS

void
CLONE(...)
CODE:
{
    MY_CXT_CLONE;
    my_cxt_initialize(aTHX_ aMY_CXT);
    PERL_UNUSED_VAR(items);
}

#endif

void
hello()
CODE:
{
    ST(0) = newSVpvs_flags("Hello, world!", SVs_TEMP);
}

@@ t/900_threads.t
#!perl -w
use strict;
use constant HAS_THREADS => eval { require threads };
use if !HAS_THREADS, 'Test::More',
    skip_all => 'multi-threading tests';

use Test::More;

use <: $dist.module :>;

my @threads;

for (1 .. 3) {
    push @threads, threads->create(sub {
        # use <: $dist.module :> here
        pass;
    });
}
$_->join for @threads;

done_testing;

@@ t/901_leaktrace.t
#!perl -w
use strict;
use Test::Requires { 'Test::LeakTrace' => 0.13 };
use Test::More;

use <: $dist.module :>;

no_leaks_ok {
    # use <: $dist.module :> here
};

done_testing;

: } # extra_files
DIST
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Template::XS - Distribution template for XS modules

=cut
