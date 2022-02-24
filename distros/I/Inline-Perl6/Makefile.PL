use 5.018000;
use Config;
use ExtUtils::MakeMaker;
use autodie;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $raku = qx{rakudo-m -e 'say \$*EXECUTABLE.absolute'};
chomp $raku;

my $moar_version_cmd = q{rakudo-m -e 'print $*VM.version ge v2021.12'};
my $moar_version = qx{$moar_version_cmd};

my $nqp_libdir_cmd = q{nqp-m -e 'print(nqp::getcomp("nqp").config<libdir>)'};
my $nqp_libdir = qx{$nqp_libdir_cmd};

my $moar_prefix = qx{rakudo-m -e 'print \$*RAKU.compiler.verbose-config<moar><prefix>'}
    or die "Failed to get MoarVM's prefix";
my $moar_includes = qx{rakudo-m -e 'print \$*RAKU.compiler.verbose-config<moar><hllincludes>'}
    or die "Failed to get MoarVM's includes";
my $inc = join(' ',
    map { "-I$moar_prefix/include/$_" }
    split ' ', $moar_includes
);

my $moar_ldflags = qx{rakudo-m -e 'print \$*RAKU.compiler.verbose-config<moar><ldflags>'}
    or die "Failed to get MoarVM's ldflags";
my $moar_lddir = qx{rakudo-m -e 'print \$*RAKU.compiler.verbose-config<moar><lddir>'}
    or die "Failed to get MoarVM's lddir";
my $moar_libdir = qx{rakudo-m -e 'print \$*RAKU.compiler.verbose-config<moar><libdir>'}
    or die "Failed to get MoarVM's libdir";

my $static_rakudo_home = qx{rakudo-m -e 'print \$*RAKU.compiler.verbose-config<Raku><static-rakudo-home>'}
    or die "Failed to get Rakudo's home";

WriteMakefile(
    NAME              => 'Inline::Perl6',
    VERSION_FROM      => 'lib/Inline/Perl6.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Inline/Perl6.pm', # retrieve abstract from module
    AUTHOR            => 'Stefan Seifert <nine@detonation.org>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => ["$moar_ldflags $moar_lddir$moar_libdir -lmoar"], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => $inc, # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

open my $header, '>', 'Perl6.h';
print { $header } qq{#define PERL6_EXECUTABLE "$raku"\n};
print { $header } qq{#define PERL6_INSTALL_PATH "$static_rakudo_home"\n};
print { $header } qq{#define NQP_LIBDIR "$nqp_libdir"\n};
print { $header } $moar_version eq 'True'
    ? qq{#define mark_thread_blocked(tc) MVM_gc_mark_thread_blocked(tc)\n}
    : qq{#define mark_thread_blocked(tc)\n};
close $header;
