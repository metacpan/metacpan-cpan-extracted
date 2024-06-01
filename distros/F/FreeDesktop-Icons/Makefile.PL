use ExtUtils::MakeMaker;

use strict;
use warnings;

my %prereq = (
	'File::Basename'				    => '2.85',
	'Test::Deep'            => '1.204',
);

WriteMakefile(
	NAME					=> 'FreeDesktop::Icons',
	VERSION_FROM		=> 'lib/FreeDesktop/Icons.pm',
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> 'lib/FreeDesktop/Icons.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
         repository => {
            type => 'git',
            url  => 'git://github.com/haje61/FreeDesktop-Icons.git',
            web  => 'https://github.com/haje61/FreeDesktop-Icons',
         },
      }}
    ) : () ),
);




