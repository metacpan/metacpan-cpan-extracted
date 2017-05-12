use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'GD::Graph::splined',
    VERSION_FROM      => 'lib/GD/Graph/splined.pm',
    PREREQ_PM         => {
		GD 				=> 2.18,	# For polyline
		GD::Polyline	=> 0.2, 	# What the hell
		GD::Graph 		=> 1.35,	# Area chart bug fixes
	},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/GD/Graph/splined.pm',
       AUTHOR         => 'Lee Goddard <lgoddard-at-cpan-dot-org>') : ()),
);
