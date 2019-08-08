use 5.008009;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME           => 'Devel::QuickCover',
    VERSION_FROM   => 'lib/Devel/QuickCover.pm',
    ABSTRACT_FROM  => 'lib/Devel/QuickCover.pm',
    LICENSE        => 'mit',
    MIN_PERL_VERSION => 5.008009,
    PREREQ_PM      => {
        'perl'                  => '5.014',
        'XSLoader'              => 0,
        'JSON::MaybeXS'         => 0,
        'Sereal'                => 0,
        'IO::Compress::Gzip'    => 0,
        'IPC::Open2'            => 0,
        'autodie'               => 0,
        'Text::MicroTemplate'   => 0,
        'File::ShareDir'        => 0,
        'File::Copy'            => 0,
        'File::Spec'            => 0,
        'File::Spec::Functions' => 0,
        'Path::Tiny'            => 0,
        'Getopt::Long'          => 0,
        'POSIX'                 => 0,
    },
    TEST_REQUIRES  => {
        'Test::More'            => 0,
        'Test::Builder::Module' => 0,
        'File::Temp'            => 0,
        'Data::Dumper'          => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'       => '7.10',
        'File::ShareDir::Install'   => 0,
    },
    AUTHOR         => [
        'Gonzalo Diethelm (gonzus@cpan.org)',
        'Andreas Guðmundsson (andreasg@nasarde.org)',
        'Andrei Vereha (avereha@cpan.org)',
    ],
    LIBS           => [''],
#    DEFINE         => '-DGMEM_CHECK',
#    DEFINE         => '-DGLOG_SHOW',
#    DEFINE         => '-DGMEM_CHECK=1 -DGLOG_SHOW',
    INC            => '-I.',
    OBJECT         => '$(O_FILES)',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:p5pclub/devel-quickcover',
                web  => 'https://github.com/p5pclub/devel-quickcover',
            },
        },
    },
    EXE_FILES     => ['bin/qc-aggregate.pl', 'bin/qc-html.pl', 'bin/qc-html-report.pl'],
);

# Add options CCFLAGS without overwriting the defaults
package MY;
use File::ShareDir::Install qw(postamble);
sub cflags {
    my $self   = shift;
    my $cflags = $self->SUPER::cflags(@_);
    my @cflags = split /\n/, $cflags;

    $self->{CCFLAGS} .= ' -Wall';                # Flag all warnings
    $self->{CCFLAGS} .= ' -std=c89';             # Compile according to C89 standard

    # Need this define for localtime_r(), except on FreeBSD
    if ($^O ne 'freebsd') {
        $self->{CCFLAGS} .= ' -D_XOPEN_SOURCE=700';
    }

    foreach (@cflags) {
        $_ = "CCFLAGS = $self->{CCFLAGS}" if /^CCFLAGS/;
    }
    return $self->{CFLAGS} = join("\n", @cflags) . "\n";
}
