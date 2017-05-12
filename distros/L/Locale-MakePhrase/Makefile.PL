use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME' => 'Locale::MakePhrase',
  'AUTHOR' => 'Mathew Robertson',
  'VERSION' => '0.5',
  'ABSTRACT' => 'Language translation facility',
  'dist' => { COMPRESS => 'gzip -9f' },
);

sub MY::postamble { return <<'MAKE_FRAG';
cover:
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover make test
	cover

coverclean:
	cover -delete
	rmdir cover_db

podcheck:
	podchecker -warnings -warnings -warnings $(MAN3PODS)

MAKE_FRAG
}


