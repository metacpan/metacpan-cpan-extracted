use ExtUtils::MakeMaker;

my $pkg_cfg = "PKG_CONFIG_PATH=/usr/local/lib/pkgconfig";
my $lwes_libs = `$pkg_cfg pkg-config lwes-0 --libs`;
my $lwes_cflags = `$pkg_cfg pkg-config lwes-0 --cflags`;

WriteMakefile(
    'NAME'           => 'LWES',
    'VERSION'        => '0.01',
    'EXE_FILES'      => [ "lwes-perl-event-listener" ],
    'PREREQ_PM'      => {
                          'IO::Socket::Multicast' => 0.98,
                        },
    'LIBS'           => $lwes_libs,
    'INC'            => $lwes_cflags,
    'OBJECT'         => 'lwes_wrap.o',
    'dynamic_lib'    => { 'OTHERLDFLAGS' => "-llwes -lm"},
);

