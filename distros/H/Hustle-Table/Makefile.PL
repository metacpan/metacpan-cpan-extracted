use strict;
use warnings;

use ExtUtils::MakeMaker;
#use File::ShareDir::Install;

#install_share dist=>"benchmark";

WriteMakefile(
	NAME => 'Hustle::Table',
	ABSTRACT_FROM => 'lib/Hustle/Table.pod', 
	VERSION_FROM => 'lib/Hustle/Table.pm',
	MIN_PERL_VERSION => '5.24.0',		#for switch and ref aliasing
	PREREQ_PM => {
		enum=>0,
		"common::sense"=>0
	},
	AUTHOR => 'Ruben Westerberg <drclaw@mac.com>',
	LICENSE => 'mit',
	TEST_REQUIRES => { "Test::More" => 0},
	CONFIGURE_REQUIRES => {"ExtUtils::MakeMaker"=>0},

	
	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl5-hustle-table.git",
				web => "http://github.com/drclaw1394/perl5-hustle-table",
			}
		}
	}



	#Value must be from legacy list of licenses here
	#http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);


#package
#MY;
#use File::ShareDir::Install qw<postamble>;
