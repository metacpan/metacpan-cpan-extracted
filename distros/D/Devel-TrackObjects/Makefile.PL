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
	}
);
