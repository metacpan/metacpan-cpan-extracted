use 5.010;
use strict;
use warnings FATAL => 'all';
use Config;
use ExtUtils::MakeMaker;
use File::Spec;

sub pkg_config {
    my (@args) = @_;
    open my $pipe, '-|', 'pkg-config', @args
        or die "pkg-config is required to locate system libwebp: $!\n";
    local $/;
    my $output = <$pipe>;
    close $pipe
        or die "pkg-config could not locate system libwebp\n";
    $output =~ s/\s+\z//;
    return $output;
}

my $webp_cflags = pkg_config('--cflags', 'libwebp');
my $webp_libs = pkg_config('--libs', 'libwebp');

if ($^O eq 'MSWin32' && $Config{'cc'} =~ /gcc/i) {
    my $libdir = pkg_config('--variable=libdir', 'libwebp');
    my $import_library = File::Spec->catfile($libdir, 'libwebp.a');
    $webp_libs = $import_library if -f $import_library;
}

WriteMakefile(
    NAME             => 'Image::WebP',
    AUTHOR           => q{Zargener <zargener@gmail.com>},
    VERSION_FROM     => 'lib/Image/WebP.pm',
    ABSTRACT_FROM    => 'lib/Image/WebP.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.88,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Image-WebP-*' },
    INC   => $webp_cflags,
    LIBS  => [$webp_libs],
);
