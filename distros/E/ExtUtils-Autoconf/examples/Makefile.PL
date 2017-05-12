use strict;
use warnings;
use ExtUtils::MakeMaker;

if (! eval 'use ExtUtils::Autoconf; 1') {
    print STDERR $@, "\n";
    WriteMakefile(
            PREREQ_FATAL => 1,
            PREREQ_PM    => {
                'ExtUtils::Autoconf' => 0,
            },
    );
    exit 1; #not reached
}

my $ac = ExtUtils::Autoconf->new;
$ac->configure;

WriteMakefile(
    NAME                => 'Foo::Bar',
    AUTHOR              => 'Florian Ragwitz <rafl@debian.org>',
    VERSION_FROM        => 'lib/Foo/Bar.pm',
    ABSTRACT_FROM       => 'lib/Foo/Bar.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
        PREOP    => q{$(PERLRUN) -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_autogen'},
    },
    clean               => { FILES => 'Foo-Bar-*' },
);

package MY;

sub postamble {
    return <<"EOM";
autogen :
\t\$(PERLRUN) -MExtUtils::Autoconf -e 'ExtUtils::Autoconf->run_autogen'

configure :
\t\$(PERLRUN) -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_configure'

autoclean :
\t\$(PERLRUN) -MExtUtils::Autoconf -e'ExtUtils::Autoconf->run_realclean'

realclean purge ::
\t\$(PERLRUN) -MExtUtils::Autoconf -e 'ExtUtils::Autoconf->run_realclean'

clean ::
\t\$(PERLRUN) -MExtUtils::Autoconf -e 'ExtUtils::Autoconf->run_clean'
EOM
}
