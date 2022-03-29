#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;

use Config;

use File::Temp;
use File::Spec;
use Cwd;

my $PERL_QJS_MAKEFILE_PATH = File::Spec->catfile( Cwd::getcwd(), 'Makefile.quickjs');

my $libpath = File::Spec->catfile('quickjs', 'libquickjs.a');

# quickjs needs these; pre-5.20 perls didn’t include libpthread:
my @libs = qw(-lm -ldl -lpthread);

# RaspiOS needs this:
if (_has_libatomic()) {
    push @libs, '-latomic';
}

make_libquickjs();

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

    LIBS => "@libs",

    OBJECT => [
        '$(BASEEXT)$(OBJ_EXT)',
        $libpath,
    ],

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

    depend => {
        $libpath => 'quickjs',
    },
);

sub _has_libatomic {
    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    open my $fh, '>', "$dir/test.c";
    syswrite $fh, join(
        "\n",
        'int main() { return 0; }',
    );

    print "Checking whether this system uses libatomic …\n";

    my $ok = !system $Config{'cc'}, "$dir/test.c", '-latomic';

    print "\t… " . ($ok ? 'Looks like it.' : 'Guess not.') . "\n";

    return $ok;
}

sub make_libquickjs {
    my $mfpath = File::Spec->catfile('quickjs', 'Makefile');

    open my $rfh, '<', $mfpath or die "open Makefile: $!";
    my $make = do { local $/; <$rfh> };

    # QuickJS builds by default without position-independent code, which
    # means the resulting static library is only suitable for executables.
    # We need position-independent code so we can compile QuickJS into a
    # shared library.
    #
    $make =~ s<^(\s*CFLAGS\s*=\s*)><$1 -fPIC >mg;

    open my $fh, '>', $PERL_QJS_MAKEFILE_PATH;
    syswrite $fh, $make or die "write custom quickjs make: $!";
}

# ----------------------------------------------------------------------
package MY;

sub postamble {
    return <<"MAKE_FRAG"

.PHONY:
build-quickjs:
\t\$(MAKE) -C quickjs -f '$PERL_QJS_MAKEFILE_PATH' libquickjs.a
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
