use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
	NAME             => 'HTML::Element::Library',
	VERSION_FROM     => 'lib/HTML/Element/Library.pm',
	ABSTRACT_FROM    => 'lib/HTML/Element/Library.pm',
	AUTHOR           => [
		'Terrence Brannon <metaperl@gmail.com>',
		'Marius Gavrilescu <marius@ieval.ro>'
	],
	MIN_PERL_VERSION => '5.6.0',
	LICENSE          => 'perl',
	SIGN             => 1,
	BUILD_REQUIRES   => {
		qw/File::Slurp         0
		   HTML::PrettyPrinter 0
		   HTML::TreeBuilder   0
		   Test::More          0
		   Test::XML           0/,
	},
	PREREQ_PM        => {
		qw/Array::Group          0
		   Data::Rmap            0
		   HTML::Element         0
		   HTML::FillInForm      0
		   List::MoreUtils       0
		   List::Rotation::Cycle 0
		   List::Util            0
		   Params::Validate      0
		   Scalar::Listify       0/,
	},
	META_MERGE         => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=html-element-library.git',
		},
	}
);
