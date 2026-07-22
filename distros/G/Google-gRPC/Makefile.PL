use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $has_nghttp2 = 0;
my $pkg_config_cflags = '';
my $pkg_config_libs = '';

my @search_dirs = (
    '/opt/homebrew/opt/nghttp2/include',
    '/opt/homebrew/include',
    '/usr/local/include',
    '/usr/include',
);

for my $dir (@search_dirs) {
    if (-f "$dir/nghttp2/nghttp2.h") {
        $has_nghttp2 = 1;
        $pkg_config_cflags = "-I$dir";
        my $libdir = $dir;
        $libdir =~ s/include$/lib/;
        $pkg_config_libs = "-L$libdir -lnghttp2";
        last;
    }
}

my $pkg_check = `pkg-config --exists libnghttp2 2>/dev/null; echo $?`;
chomp($pkg_check) if defined $pkg_check;

if (!$has_nghttp2 && defined $pkg_check && $pkg_check eq '0') {
    $has_nghttp2 = 1;
    $pkg_config_cflags = `pkg-config --cflags libnghttp2 2>/dev/null`;
    $pkg_config_libs   = `pkg-config --libs libnghttp2 2>/dev/null`;
    chomp($pkg_config_cflags) if defined $pkg_config_cflags;
    chomp($pkg_config_libs) if defined $pkg_config_libs;
}

my %extra_params;

if ($has_nghttp2) {
    print 'libnghttp2 detected. Configuring C/XS engine (Google::gRPC::Engine::NGHTTP2).', "\n";
    $extra_params{INC} = '-I. -Ixs ' . $pkg_config_cflags;
    $extra_params{LIBS} = [$pkg_config_libs || '-lnghttp2'];
    $extra_params{XS} = { 'NGHTTP2.xs' => 'NGHTTP2.c' };
    $extra_params{OBJECT} = 'NGHTTP2$(OBJ_EXT)';
    $extra_params{DEFINE} = '-DHAVE_NGHTTP2';
}
else {
    print 'libnghttp2 headers not found. Falling back to Pure-Perl HTTP/2 engine.', "\n";
    $extra_params{C} = [];
    $extra_params{OBJECT} = '';
}

WriteMakefile(
    NAME             => 'Google::gRPC',
    AUTHOR           => q{C.J. Collier <CJCOLLIER@CPAN.ORG>},
    VERSION_FROM     => 'lib/Google/gRPC/Client.pm',
    ABSTRACT         => 'Generic, high-performance gRPC client transport over HTTP/2',
    LICENSE          => 'Apache 2.0',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Moo'             => '0',
        'Protocol::HTTP2' => '0.13',
        'Protobuf'        => '0.01',
        'Log::Any'        => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Google-gRPC-* xs/*.o xs/*.c *.o NGHTTP2.c' },
    %extra_params,
);
