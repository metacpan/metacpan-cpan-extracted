use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                 => 'ExtJS::AutoForm::Moose',
    AUTHOR               => q{Quim Rovira <quim@rovira.cat>},
    VERSION_FROM         => 'lib/ExtJS/AutoForm/Moose.pm',
    ABSTRACT_FROM        => 'lib/ExtJS/AutoForm/Moose.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES             => {},
    PREREQ_PM => {
        'Test::More'     => 0,
	'JSON::Any'      => 0,
	'Moose'		 => 0,
    },
    dist                 => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                => { FILES => 'ExtJS-AutoForm-Moose-*' },
);
