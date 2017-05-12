use ExtUtils::MakeMaker;

WriteMakefile
(
	'NAME'         => 'Games::Cryptoquote',
	'VERSION_FROM' => 'Cryptoquote.pm',
	(
		$] >= 5.005 ?
		(
			ABSTRACT_FROM => 'Cryptoquote.pm',
			AUTHOR        => 'Bob O\'Neill <bobo@cpan.org>',
		) : ()
	),
);
