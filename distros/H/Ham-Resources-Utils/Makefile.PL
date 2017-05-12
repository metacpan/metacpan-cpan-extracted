use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Ham::Resources::Utils',
    AUTHOR              => q{CJUAN <cjuan@cpan.org>},
    VERSION_FROM        => 'lib/Ham/Resources/Utils.pm',
    ABSTRACT_FROM       => 'lib/Ham/Resources/Utils.pm',
    ($ExtUtils::MakeMaker::VERSION ge '6.3002'
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM 		=> {
        	'Test::More' 	=> 0,
  		'Math::Trig' 	=> 0,
		'Ham::Locator' 	=> 0,	
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Ham-Resources-Utils-*' },
);
