use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'HTTP::XSHeaders',
    VERSION_FROM   => 'lib/HTTP/XSHeaders.pm',
    ABSTRACT_FROM  => 'lib/HTTP/XSHeaders.pm',
    LICENSE        => 'mit',
    MIN_PERL_VERSION => 5.008009,
    PREREQ_PM      => {
        'Test::More' => 0,
        'Exporter'   => '5.57',
        'XSLoader'   => 0,
    },
    AUTHOR         => [
        'Gonzalo Diethelm (gonzus@cpan.org)',
        'Sawyer X (xsawyerx@cpan.org)',
    ],
    LIBS           => [''],
#    DEFINE         => '-DGMEM_CHECK',
#    DEFINE         => '-DGLOG_SHOW',
#    DEFINE         => '-DGMEM_CHECK -DGLOG_SHOW',
    INC            => '-I.',
    OBJECT         => '$(O_FILES)',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:p5pclub/http-xsheaders.git',
                web  => 'https://github.com/p5pclub/http-xsheaders',
            },
        },
    },
);

# Add -Wall to CCFLAGS without overwriting the defaults
package MY;
sub cflags {
    my $self   = shift;
    my $cflags = $self->SUPER::cflags(@_);
    my @cflags = split /\n/, $cflags;

    $self->{CCFLAGS} .= ' -Wall';     # Flag all warnings
    $self->{CCFLAGS} .= ' -std=c89';  # Compile according to C99 standard

    # $self->{CCFLAGS} .= ' -pedantic'; # Be pedantic about warnings - no GNU extensions
    # These warnings show up in internal XSUB code, so just shut them up.
    # $self->{CCFLAGS} .= ' -Wno-gnu-statement-expression';

    foreach (@cflags) {
        $_ = "CCFLAGS = $self->{CCFLAGS}" if /^CCFLAGS/;
    }
    return $self->{CFLAGS} = join("\n", @cflags) . "\n";
}
