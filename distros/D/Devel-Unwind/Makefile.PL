use ExtUtils::MakeMaker;

use utf8;

WriteMakefile(
    NAME => "Devel::Unwind",
    ABSTRACT_FROM => "lib/Devel/Unwind.pm",
    VERSION_FROM  => "lib/Devel/Unwind.pm",
    LICENSE => "perl",
    AUTHOR => 'Andreas Guðmundsson (andreasg@cpan.org)',
    MIN_PERL_VERSION => '5.14.0',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:andreasgudmundsson/p5-Devel-Unwind',
                web  => 'https://github.com/andreasgudmundsson/p5-Devel-Unwind',
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

    $self->{CCFLAGS} .= ' -Wall ';
    $self->{CCFLAGS} .= ' -Wextra';
    $self->{CCFLAGS} .= ' -Wno-unused-function';
    $self->{CCFLAGS} .= ' -Wno-unused-label';
    $self->{CCFLAGS} .= ' -std=c89 ';

    foreach (@cflags) {
        $_ = "CCFLAGS = $self->{CCFLAGS}" if /^CCFLAGS/;
    }
    return $self->{CFLAGS} = join("\n", @cflags) . "\n";
}
