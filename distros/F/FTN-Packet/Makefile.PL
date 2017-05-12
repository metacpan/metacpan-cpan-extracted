use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
#  the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'FTN::Packet',
    AUTHOR              => 'Robert James Clay <jame@rocasa.us>',
    VERSION_FROM        => 'lib/FTN/Packet.pm',
    ABSTRACT_FROM       => 'lib/FTN/Packet.pm', 
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More'            => 0,
        'Test::Pod'             => 1.22,
        'Test::Pod::Coverage'   => 1.08
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                type => 'git',
                url  => 'git.code.sf.net/p/ftnpl/ftn-packet/code',
                web  => 'http://sourceforge.net/p/ftnpl/ftn-packet/code',
             },
         }})
        : ()
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', ZIPFLAGS => '-or9',},
    clean               => { FILES => 'FTN-Packet-*' },
);
