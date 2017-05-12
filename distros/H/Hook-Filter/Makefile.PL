use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Hook::Filter',
    VERSION_FROM      => 'lib/Hook/Filter.pm',
    PREREQ_PM         => {
	Module::Pluggable => 2.2,
	File::Spec        => 0.86,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Hook/Filter.pm',
       AUTHOR         => 'Erwan Lemonnier <erwan@cpan.org>') : ()),
);
