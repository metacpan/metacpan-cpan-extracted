use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'HTTP::XSCookies',
    VERSION_FROM   => 'lib/HTTP/XSCookies.pm',
    ABSTRACT_FROM  => 'lib/HTTP/XSCookies.pm',
    LICENSE        => 'mit',
    MIN_PERL_VERSION => 5.008009,
    PREREQ_PM      => {
        'XSLoader'    => 0,
    },
    TEST_REQUIRES  => {
        'Test::More'            => 0,
        'Data::Dumper'          => 0,
        'Date::Parse'           => 0,
    },
    AUTHOR         => [
        'Gonzalo Diethelm (gonzus@cpan.org)',
    ],
    LIBS           => [''],
#    DEFINE         => '-DGMEM_CHECK',
    INC            => '-I.',
    OBJECT         => '$(O_FILES)',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:gonzus/http-xscookies',
                web  => 'https://github.com/gonzus/http-xscookies',
            },
        },
    },
);

# Add options CCFLAGS without overwriting the defaults
package MY;
sub cflags {
    my $self   = shift;
    my $cflags = $self->SUPER::cflags(@_);
    my @cflags = split /\n/, $cflags;

    $self->{CCFLAGS} .= ' -Wall';                # Flag all warnings

    # solaris refuses to compile unless we are using C99
    if ($^O eq 'solaris') {
        $self->{CCFLAGS} .= ' -std=c99';
    } else {
        $self->{CCFLAGS} .= ' -std=c89';
    }

    # Need this define for localtime_r(), except on FreeBSD
    if ($^O ne 'freebsd') {
        $self->{CCFLAGS} .= ' -D_XOPEN_SOURCE=700';
    }

    foreach (@cflags) {
        $_ = "CCFLAGS = $self->{CCFLAGS}" if /^CCFLAGS/;
    }
    return $self->{CFLAGS} = join("\n", @cflags) . "\n";
}
