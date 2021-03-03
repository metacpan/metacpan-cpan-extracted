use ExtUtils::MakeMaker;


# make sure that weaken works
if ( eval { require Scalar::Util } ) {
    eval { my $x; Scalar::Util::weaken(\$x ) };
    if ($@) {
	warn "Scalar::Util::weaken is not available for this perl: $@";
	exit(0)
    }
}

WriteMakefile(
    NAME => 'Devel::TrackObjects',
    VERSION_FROM => 'lib/Devel/TrackObjects.pm',
    PREREQ_PM => {
	'Scalar::Util' => 1.00,
    },
    META_MERGE => {
	resources => {
	    license => 'http://dev.perl.org/licenses/',
	    homepage  => 'https://github.com/noxxi/p5-devel-trackobjects',
	    repository => 'https://github.com/noxxi/p5-devel-trackobjects',
	    bugtracker => 'https://github.com/noxxi/p5-devel-trackobjects/issues',
	},
   },
);
