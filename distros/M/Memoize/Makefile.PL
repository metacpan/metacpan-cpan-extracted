use 5.006; use strict; use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'Memoize',
	      AUTHOR => 'Mark Jason Dominus',
	      ( eval { ExtUtils::MakeMaker->VERSION('6.06_03') } ? ( ABSTRACT_FROM => 'Memoize.pm' ) : () ),
	      ( eval { ExtUtils::MakeMaker->VERSION('6.45_01') } ? ( META_ADD => {
		'meta-spec' => { version => 2 },
		resources => {
		  repository => { type => 'git', map +( url => "$_.git", web => $_ ), 'https://github.com/ap/Memoize' },
		  bugtracker => { web => 'https://rt.cpan.org/Dist/Display.html?Name=Memoize' }
		},
		prereqs => {
		  runtime => {
		    requires => { perl => '5.006' },
		    suggests => { Storable => '1.002' },
		  },
		  test => {
		    requires => { 'Test::More' => 0 },
		  },
		},
		dynamic_config => 0,
	      } ) : () ),
	      VERSION_FROM => 'Memoize.pm',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
	      ( "$]" < 5.011 ? ( INSTALLDIRS => 'perl' ) : () ),
);

sub MY::postamble { -f 'META.yml' ? return : <<'' }
create_distdir : MANIFEST
distdir        : MANIFEST
MANIFEST :
	( echo MANIFEST ; git ls-files ) | sort -f > MANIFEST

