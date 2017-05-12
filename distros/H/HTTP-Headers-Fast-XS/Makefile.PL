use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'HTTP::Headers::Fast::XS',
    VERSION_FROM   => 'lib/HTTP/Headers/Fast/XS.pm',
    ABSTRACT_FROM  => 'lib/HTTP/Headers/Fast/XS.pm',
    PREREQ_PM      => {
        'Test::More'          => 0,
        'Exporter'            => '5.57',
        'XSLoader'            => 0,
        'HTTP::Headers::Fast' => '0.19',
    },
    AUTHOR         => [
        'Sawyer X (xsawyerx@cpan.org)',
        'Andrei Vereha (avereha@cpan.org)',
        'Steven Lee (stevenl@cpan.org)',
        'Gonzalo Diethelm (gonzus@cpan.org)',
    ],
    LIBS           => [''],
    DEFINE         => '',
    INC            => '-I.',
    #OBJECT         => '$(O_FILES)',
);

# Add -Wall to CCFLAGS without overwriting the defaults
package MY;
sub cflags {
    my $self   = shift;
    my $cflags = $self->SUPER::cflags(@_);
    my @cflags = split /\n/, $cflags;

    $self->{CCFLAGS} .= ' -Wall';
    foreach (@cflags) {
        $_ = "CCFLAGS = $self->{CCFLAGS}" if /^CCFLAGS/;
    }
    return $self->{CFLAGS} = join("\n", @cflags) . "\n";
}
