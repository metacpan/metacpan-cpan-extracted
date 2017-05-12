use 5.10.0;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'HTTP::ClickHouse',
    VERSION_FROM      => 'lib/HTTP/ClickHouse.pm',
    PREREQ_PM         => {
        'Net::HTTP::NB'			=> 6.09,
	'HTTP::ClickHouse::Base'	=> 0,
        'URI'				=> 1.71,
        'URI::QueryParam'		=> 1.71,
        'Storable'			=> 2.51,
        'Data::Dumper'			=> 2.161,
        'IO::Select'			=> 1.22,
        'Scalar::Util'			=> 1.46,
        'Carp'         		=> 0,
        'strict'        	=> 0,
        'warnings'      	=> 0,
    }, 
    ABSTRACT_FROM     => 'lib/HTTP/ClickHouse.pm', 
    AUTHOR            => 'Maxim Motylkov <mmv@cpan.org>',
    LICENSE           => 'perl',
    META_MERGE		=> {
    	requires	=> {
    		perl	=> '5.10.0'
    	}
    }
);
