use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Math::RungeKutta',
	VERSION_FROM => 'RungeKutta.pm',
	AUTHOR    => 'PJB, Peter Billam, www.pjb.com.au/comp/contact.html',
	ABSTRACT  => 'Runge-Kutta algorithm for Differential Equations',
	dist      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
);
