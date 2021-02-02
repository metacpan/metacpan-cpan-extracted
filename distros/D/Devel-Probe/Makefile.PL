use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Devel::Probe',
    VERSION_FROM   => 'lib/Devel/Probe.pm',
    ABSTRACT_FROM  => 'lib/Devel/Probe.pm',
    LICENSE        => 'mit',
    MIN_PERL_VERSION => 5.018000,
    PREREQ_PM      => {
        'XSLoader'     => 0,
        'Carp'         => 0,
        'Storable'     => 0,
    },
    TEST_REQUIRES  => {
        'Test::More'   => 0,
        'Devel::Leak'  => 0,
    },
    AUTHOR         => [
        'Gonzalo Diethelm (gonzus@cpan.org)',
    ],
    INC            => '-I.',
    OBJECT         => '$(O_FILES)',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:gonzus/Devel-Probe.git',
                web  => 'https://github.com/gonzus/Devel-Probe.git',
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

    # turn on a bunch of warning flags
    my @warning_flags_always = qw/
        all
        extra
        declaration-after-statement
        comment
    /;
    $self->{CCFLAGS} .= " -W$_" for @warning_flags_always;

    foreach (@cflags) {
        $_ = "CCFLAGS = $self->{CCFLAGS}" if /^CCFLAGS/;
    }

    return $self->{CFLAGS} = join("\n", @cflags) . "\n";
}
