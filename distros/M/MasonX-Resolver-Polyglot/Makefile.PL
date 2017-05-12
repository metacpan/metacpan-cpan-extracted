use 5.008;

use ExtUtils::MakeMaker;

my %prereq_pm = (
		 HTML::Mason      => 1.1, 
		 Locale::Language => 2.02,
		 Locale::Country  => 2.06
		 );

		 

WriteMakefile(
	      NAME              => 'MasonX::Resolver::Polyglot',
	      VERSION_FROM      => 'lib/MasonX/Resolver/Polyglot.pm', 
	      PREREQ_PM         => \%prereq_pm
	      );

