#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;

use Config;

use File::Temp;
use File::Slurper;
use File::Spec;
use File::Which;
use Cwd;

my $GMAKE_PATH = _find_gmake();

if (!$GMAKE_PATH) {
    die "GNU Make ($Config{'gmake'}) is required.\n";
}
elsif (!-x $GMAKE_PATH) {
    if ($!) {
        die "Failed to detect if GNU Make ($GMAKE_PATH) is executable: $!\n";
    }

    die "GNU Make ($GMAKE_PATH) is not executable.\n";
}

my $ATOMIC_ENV_KEY = 'JS_QUICKJS_LINK_LIBATOMIC';

my $PERL_QJS_MAKEFILE_PATH = File::Spec->catfile( Cwd::getcwd(), 'Makefile.quickjs');

my $libpath = File::Spec->catfile('quickjs', 'libquickjs.a');

# quickjs needs these; pre-5.20 perls didn’t include libpthread:
my @libs = qw(-lm -ldl -lpthread);

if (_need_librt()) {
    push @libs, '-lrt';
}

_tweak_for_os();

if (!_stdatomic_h_exists()) {
    _avoid_stdatomic_h();
}

make_libquickjs_makefile();

# RaspiOS needs this; others may, too:
if (_should_link_libatomic()) {
    push @libs, '-latomic';
}

WriteMakefile(
    NAME              => 'JavaScript::QuickJS',
    VERSION_FROM      => 'lib/JavaScript/QuickJS.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/JavaScript/QuickJS.pm', # retrieve abstract from module
       AUTHOR         => [
            'Felipe Gasper (FELIPE)',
        ],
      ) : ()
    ),
    INC               => '-Wall --std=c99 -I.',
    LICENSE           => "perl_5",

    PMLIBDIRS => ['lib'],

    LIBS => "@libs",

    OBJECT => join(
        q< >,
        '$(BASEEXT)$(OBJ_EXT)',
        $libpath,
    ),

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-JavaScript-QuickJS.git',
                web => 'https://github.com/FGasper/p5-JavaScript-QuickJS',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-JavaScript-QuickJS/issues',
            },
        },
    },
);

#----------------------------------------------------------------------

# CPAN offers Alien::gmake, but there’s a significant dependency tree
# involved there.
sub _find_gmake {
    my $gmake;

    if (my $make = File::Which::which($Config{'make'})) {
        my $out = `$make --version`;
        if ($out =~ m<gnu>i) {
            $gmake = $make;
        }
    }

    $gmake ||= File::Which::which($Config{'gmake'});

    return $gmake;
}

sub _tweak_for_os {
    my %bsd_fix = (
        Makefile => sub {
            return "CONFIG_DARWIN=y$/" . shift;
        },

        'quickjs-libc.c' => sub {
            return join(
                $/,
                'extern char **environ;',
                '#include <signal.h>',
                'typedef sig_t sighandler_t;',
                shift
            );
        },
    );

    my %edits = (
        cygwin => {
            'quickjs.c' => sub {
                return "#include <malloc.h>$/" . shift;
            },
        },

        freebsd => \%bsd_fix,

        openbsd => {
            %bsd_fix,

            'quickjs.c' => sub {

                # OpenBSD 6.5 seems to have *deleted* this function,
                # so we can assume it won’t return.
                #
                # https://www.openbsd.org/plus65.html
                # https://fjordtek.com/git/Fincer/openntpd-openbsd/commit/1bb7064e52f2efe021728e66eb627bae7c9fae71
                #
                return "#define malloc_usable_size js_malloc_usable_size_unknown$/" . shift;
            },
        },
    );

    if (my $edits_h = $edits{$^O}) {
        my $touchfile_path = File::Spec->catfile('quickjs', 'js-qjs-tweaked');

        if (-e $touchfile_path) {
            print "QuickJS is already tweaked for $^O compatibility.$/";
        }
        else {
            print "Tweaking QuickJS for $^O compatibility …$/";

            for my $fname (keys %$edits_h) {
                my $path = "quickjs/$fname";

                my $content = File::Slurper::read_binary($path);

                my $out = $edits_h->{$fname}->($content);
                File::Slurper::write_binary($path, $out);
            }

            print "Done.$/";

            open my $fh, '>', $touchfile_path;
        }
    }
    else {
        print "No tweaks for $^O are available. Hopefully none are needed!$/";
    }
}

# In CloudLinux 6, glibc is old enough to need -lrt. Test for that.
#
my $_cached_need_librt;
sub _need_librt {
    return $_cached_need_librt if defined $_cached_need_librt;

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    open my $fh, '>', "$dir/test.c";
    syswrite $fh, join(
        "\n",
        '#include <stdlib.h>',
        '#ifdef __GLIBC__',
        '#  if __GLIBC__ < 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ < 17)',
        '#      error "This system needs librt"',
        '#  endif',
        '#endif',
        'int main() { return 0; }',
    );

    print "Checking whether this system needs to link to librt …\n";

    my $ok = !!system $Config{'cc'}, "$dir/test.c";

    print "\t… " . ($ok ? 'Looks like it.' : 'Guess not.') . "\n";

    return $_cached_need_librt = $ok;
}

sub _should_link_libatomic {
    -e $PERL_QJS_MAKEFILE_PATH or die "Need quickjs makefile!";

    my $env_value = $ENV{$ATOMIC_ENV_KEY};

    if (defined $env_value) {
        if ($env_value) {
            if ($env_value ne '1') {
                die "Set $ATOMIC_ENV_KEY to 1 or a falsy value.\n";
            }

            print "You’ve forcibly enabled linking against libatomic.\n";
            return 1;
        }
        else {
            print "You’ve forcibly disabled linking against libatomic.\n";
            return 0;
        }
    }

    print "Does QuickJS need -latomic? (compiling core object file) …\n";

    my $rel_objpath = File::Spec->catfile( qw( .obj quickjs.nolto.o ) );
    my $objpath = File::Spec->catfile( 'quickjs', $rel_objpath );

    my $needs_libatomic;

    eval {
        system $GMAKE_PATH, '-C', 'quickjs', '-f', $PERL_QJS_MAKEFILE_PATH, $rel_objpath;
        die if $?;
        my $objbin = File::Slurper::read_binary($objpath);

        $needs_libatomic = -1 != index($objbin, '__atomic_fetch_sub_');
    };

    if ($@) {
        print "\tFailed to detect (assuming no): $@";
    }
    else {
        print "\t… " . ($needs_libatomic ? 'Looks like it.' : 'Guess not.') . "\n";
    }

    return $needs_libatomic;
}

sub _stdatomic_h_exists {
    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    open my $fh, '>', "$dir/test.c";
    syswrite $fh, join(
        "\n",
        '#include <stdatomic.h>',
        'int main() { return 0; }',
    );

    print "Checking whether stdatomic.h exists …\n";

    my $ok = !system $Config{'cc'}, "$dir/test.c";

    print "\t… " . ($ok ? 'Looks like it.' : 'Guess not.') . "\n";

    return $ok;
}

sub _avoid_stdatomic_h {
    print "Tweaking QuickJS to avoid use of stdatomic.h …\n";

    my $qjs_c_path = File::Spec->catfile( qw( quickjs quickjs.c ) );

    my $quickjs_c = File::Slurper::read_binary($qjs_c_path);

    $quickjs_c =~ s<^#define\s+CONFIG_ATOMICS></* no atomics - J::QJS */>m or do {
        warn "Did no replace for quickjs.c?\n";
    };
    File::Slurper::write_binary($qjs_c_path, $quickjs_c);

    my $qjs_libc_path = File::Spec->catfile( qw( quickjs quickjs-libc.c ) );
    my $quickjs_libc_c = File::Slurper::read_binary($qjs_libc_path);

    $quickjs_libc_c =~ s<^#define\s+USE_WORKER></* no atomics - J::QJS */>m or do {
        warn "Did no replace for quickjs-libc.c?\n";
    };
    File::Slurper::write_binary($qjs_libc_path, $quickjs_libc_c);
}

sub make_libquickjs_makefile {
    my $mfpath = File::Spec->catfile('quickjs', 'Makefile');

    open my $rfh, '<', $mfpath or die "open Makefile: $!";
    my $make = do { local $/; <$rfh> };

    # QuickJS builds by default without position-independent code, which
    # means the resulting static library is only suitable for executables.
    # We need position-independent code so we can compile QuickJS into a
    # shared library.
    #
    $make =~ s<^(\s*CFLAGS\s*=\s*)><$1 -fPIC >mg;

    # In systems old enough to need -lrt (e.g., CloudLinux 6),
    # assume we need these other omissions as well:
    #
    if (_need_librt()) {
        $make =~ s<^(.*no-format-truncation)><#$1 -- J::QJS>m;
        $make =~ s<^(CONFIG_BIGNUM)><#$1 -- J::QJS>m;
        $make =~ s<^(CONFIG_LTO)><#$1 -- J::QJS>m;
    }

    open my $fh, '>', $PERL_QJS_MAKEFILE_PATH or die "open($PERL_QJS_MAKEFILE_PATH): $!";
    syswrite $fh, $make or die "write custom quickjs make: $!";
    print "Created `$PERL_QJS_MAKEFILE_PATH`$/";
}

# ----------------------------------------------------------------------
package MY;

use Config;

sub postamble {
    return <<"MAKE_FRAG"

.PHONY:
build-quickjs:
\t$GMAKE_PATH -C quickjs -f '$PERL_QJS_MAKEFILE_PATH' libquickjs.a
MAKE_FRAG
}

my $orig_top_targets;
BEGIN {
$orig_top_targets = __PACKAGE__->can('top_targets');
}

sub top_targets {
    my $out = $orig_top_targets->(@_);

    $out =~ s<^(all\s*:+s*)><$1 build-quickjs >;

    return $out;
}
