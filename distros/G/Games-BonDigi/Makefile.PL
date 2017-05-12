use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Games::BonDigi',
    VERSION_FROM    => 'lib/Games/BonDigi.pm',
    PREREQ_PM       => {
        'Test::More'        => '0.47',
        'Test::Class'       => '0.27',
    },
	NO_META			=> 1,
    ($] >= 5.005 ?
        (AUTHOR     => 'Cosimo Streppone <cosimo@cpan.org>') : ()),
);
