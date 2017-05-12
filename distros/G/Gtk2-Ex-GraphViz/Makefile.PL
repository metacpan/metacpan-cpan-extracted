use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::GraphViz',
    AUTHOR              => 'Ofey Aikon <ofey aikon @ cpan org>',
    VERSION_FROM        => 'lib/Gtk2/Ex/GraphViz.pm',
    ABSTRACT_FROM       => 'lib/Gtk2/Ex/GraphViz.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Gtk2::TestHelper' => 0,     
		'Glib' => 0,
		'Data::Dumper' => 0,
		'GraphViz' => 0,
		'Gtk2' => 0,
		'XML::Simple' => 0,
		'Math::Geometry::Planar' => 0,
		'GD' => 0,
		'GD::Polyline' => 0,    
	},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-GraphViz-*' },
);
