use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile (NAME => 'Math::MatrixDecomposition',
	       VERSION_FROM => 'lib/Math/MatrixDecomposition.pm',
	       ABSTRACT_FROM => 'lib/Math/MatrixDecomposition.pm',
	       AUTHOR => 'Ralph Schleicher <rs@ralph-schleicher.de>',
	       LICENSE => 'perl',
	       # Dependencies.
	       MIN_PERL_VERSION => '5.010',
	       PREREQ_PM =>
	       {
		"Math::BLAS" => 0,
	       });
