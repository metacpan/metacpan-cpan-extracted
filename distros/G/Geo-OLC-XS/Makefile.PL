use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Geo::OLC::XS',
    VERSION_FROM   => 'lib/Geo/OLC/XS.pm',
    ABSTRACT_FROM  => 'lib/Geo/OLC/XS.pm',
    LICENSE        => 'mit',
    MIN_PERL_VERSION => 5.018000,
    PREREQ_PM      => {
        'XSLoader'     => 0,
    },
    TEST_REQUIRES  => {
        'Data::Dumper' => 0,
        'Test::More'   => 0,
    },
    AUTHOR         => [
        'Gonzalo Diethelm (gonzus@cpan.org)',
    ],
    LIBS           => [ '-lolc' ],
    OBJECT         => '$(O_FILES)',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:gonzus/Geo-OLC-XS',
                web  => 'https://github.com/gonzus/Geo-OLC-XS',
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
