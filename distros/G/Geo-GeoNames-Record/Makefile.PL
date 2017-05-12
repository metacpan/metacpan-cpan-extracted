use 5.008007;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my @prog = qw/gn_txt_to_sqlite gn_update_admins gn_query/;

WriteMakefile( NAME              => 'Geo::GeoNames::Record',
	       VERSION_FROM      => 'lib/Geo/GeoNames/Record.pm', # finds $VERSION
	       PREREQ_PM         => {
				     'DBD::SQLite' => 0,
				     'File::HomeDir' => 0,
				     'LWP' => 0,
				    }, 
	       ABSTRACT_FROM  => 'lib/Geo/GeoNames/Record.pm', 
	       AUTHOR         => 'Xiangrui Meng <mengxr@stanford.edu>',
	       EXE_FILES      => [ map "bin/$_", @prog ],
	     );
