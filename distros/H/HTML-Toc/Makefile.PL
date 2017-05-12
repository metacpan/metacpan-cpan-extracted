use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'HTML::Toc',
    VERSION_FROM => 'Toc.pm',
    AUTHOR       => 'Freddy Vulto (fvulto@gmail.com)',
    ABSTRACT     => 'Generate, insert and update HTML Table of Contents',
    PREREQ_PM    => {'HTML::Parser' => 0, 'Test::Differences' => 0},
    MAN3PODS     => {},
);

package MY; # so that "SUPER" works right

sub test {
    my $inherited = shift->SUPER::test(@_);

    if ($^O eq 'MSWin32') {
        $inherited =~ s/(?=\$\(FULLPERLRUN\))/SET PERLIO=perlio & /;
    } # if
    return $inherited;
} # test()
