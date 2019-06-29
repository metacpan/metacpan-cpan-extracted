use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'JavaScript::Duktape::XS',
    VERSION_FROM   => 'lib/JavaScript/Duktape/XS.pm',
    ABSTRACT_FROM  => 'lib/JavaScript/Duktape/XS.pm',
    LICENSE        => 'mit',
    MIN_PERL_VERSION => 5.014000,
    PREREQ_PM      => {
        'JSON::PP'     => 0,
        'XSLoader'     => 0,
    },
    TEST_REQUIRES  => {
        'Data::Dumper'       => 0,
        'JSON::PP'           => 0,
        'Path::Tiny'         => 0,
        'Scalar::Util'       => 0,
        'Test::Exception'    => 0,
        'Test::More'         => 0,
        'Test::Output'       => 0,
        'Text::Trim'         => 0,
        'Time::HiRes'        => 0,
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
                url  => 'git@github.com:gonzus/JavaScript-Duktape-XS',
                web  => 'https://github.com/gonzus/JavaScript-Duktape-XS',
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
