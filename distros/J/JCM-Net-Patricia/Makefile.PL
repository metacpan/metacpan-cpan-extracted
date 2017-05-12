use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'JCM::Net::Patricia',
    'ABSTRACT_FROM' => 'lib/JCM/Net/Patricia.pm',
    'AUTHOR'        => 'Joel Maslak <jmaslak@antelope.net>',
    'LICENSE'       => 'gpl_2',
    'VERSION_FROM'  => 'lib/JCM/Net/Patricia.pm',
    'LIBS'          => [],
    'DEFINE'        => '',
    'INC'           => '',
    'MYEXTLIB'      => 'libpatricia/libpatricia$(LIB_EXT)',
    'PREREQ_PM'     => {
        'Socket6'         => 0,
        'version'         => 0,
        'Test::More'      => '0.88',
        'Net::CIDR::Lite' => '0.20',
    },
    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        resources   => {
            respoistory => {
                type => 'git',
                url  => 'git://git@github.com/jmaslak/JCM-Net-Patricia.git',
                web  => 'https://github.com/jmaslak/JCM-Net-Patricia',
            },
        },
    },
    'PERL_MALLOC_OK' => 1,
);

sub MY::postamble {
    '
$(MYEXTLIB): libpatricia/Makefile
	cd libpatricia && $(MAKE) $(PASTHRU)
';
}
