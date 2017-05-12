use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Language::AttributeGrammar',
    VERSION_FROM      => 'lib/Language/AttributeGrammar.pm', 
    PREREQ_PM         => {
                Perl6::Attributes => 0,
                Parse::RecDescent => 0,
                Carp::Clan        => 0,
				Test::Exception   => 0,
	},
    ABSTRACT_FROM     => 'lib/Language/AttributeGrammar.pm',
    AUTHOR            => 'Luke Palmer <lrpalmer@gmail.com>',
);
