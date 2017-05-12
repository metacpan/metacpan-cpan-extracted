use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'Excel::Template::Element::Cell::AutoSize',
	VERSION_FROM	=> 'lib/Excel/Template/Element/Cell/AutoSize.pm',
	AUTHOR		=> 'Tim Howell (tim@fefcful.org)',
	ABSTRACT		=> 'Excel::Template::Element::Cell::AutoSize',
	PREREQ_PM		=> {
					'Excel::Template' => 0.12,
					'Font::TTFMetrics' => 0.1
				  	}
);
