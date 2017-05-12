use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::Graph::GD',
    AUTHOR              => 'Ofey Aikon <ofey.aikon@gmail.com>',
    VERSION_FROM        => 'lib/Gtk2/Ex/Graph/GD.pm',
    #ABSTRACT_FROM       => 'lib/Gtk2/Ex/Graph/GD.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'GD::Graph::bars' => 0,
		'GD::Graph::pie' => 0,
		'GD::Graph::lines' => 0,
		'GD::Graph::linespoints' => 0,
		'GD::Graph::area' => 0,
		'Gtk2' => 0,
		'Glib' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-Graph-GD-*' },
);
