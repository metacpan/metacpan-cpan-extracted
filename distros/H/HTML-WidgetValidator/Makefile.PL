use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WidgetValidator',
    AUTHOR              => 'Takaaki Mizuno <cpan@takaaki.info>',
    VERSION_FROM        => 'lib/HTML/WidgetValidator.pm',
    ABSTRACT_FROM       => 'lib/HTML/WidgetValidator.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Base'               => 0,
        'Class::Accessor::Fast'    => 0,
	'Class::Data::Inheritable' => 0,
        'HTML::Parser'             => 0,
	'List::MoreUtils'          => 0,
	'UNIVERSAL::require'       => 0,
	'Module::Pluggable'        => 0,
        'version'                  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WidgetValidator-*' },
);
