#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

use Config::Tiny;
use File::Copy;

my $conf_file = ( -e 'freeradius_database.conf-dist' )
	? 'freeradius_database.conf-dist'
	: 'src/conf/freeradius_database.conf-dist';

my $config = Config::Tiny->read( $conf_file );

print "\n\n\n" .
	  "##########################################\n\n" .
	  "Welcome to the FreeRADIUS::Database installer.\n\n" .
	  "##########################################\n\n"; 

print <<EOT;


We need to ask a few questions regarding the location of certain
directories.

This won't take long ;)



EOT

#
# these are the config file directives
#

my %directives = (
				config_dir		=> "Where should I install the config file [$config->{ Global }->{ config_dir }]: ",
				script_dir		=> "Binary scripts will be installed here [$config->{ Global }->{ script_dir }]: ",
			);

for my $directive ( keys %directives ) {

	print "$directives{ $directive }";
	
	my $response = <STDIN>;
	chomp $response;
	
	$config->{ Global }{ $directive } = $response if $response;

}

$config->write( 'freeradius_database.conf-dist' );

#
# now configure the actual system
#

# install the test infrastructure

copy 'src/schema/_test_radius.db', 't/';
copy 'freeradius_database.conf-dist', 't/';

sub MY::postamble {
	
"

CONFDIR 	= $config->{ Global }{ config_dir }
SCRIPTDIR	= $config->{ Global }{ script_dir } 

"

.

'
install:: all conf 
clean::	clean_sourcedirs clean_test

clean_sourcedirs:
	rm -f doc/*.conf
	rm freeradius_database.conf-dist

clean_test:
	rm t/freeradius_database.conf-dist
	rm t/_test_radius.db

conf:
	install -m 0640 freeradius_database.conf-dist ${CONFDIR}

docs:
	pod2text lib/FreeRADIUS/freeradius_database.conf.pod	> doc/freeradius_database.conf 

scripts:

	cp src/utilities/* ${SCRIPTDIR}
';

}

sub nothing{} # fold placeholder for vim

WriteMakefile(
    NAME                => 'FreeRADIUS::Database',
    AUTHOR              => 'Steve Bertrand <steve@ibctech.ca>',
    VERSION_FROM		=> 'lib/FreeRADIUS/Database.pm',

    ABSTRACT       		=> 'FreeRADIUS::Database - FreeRADIUS database manager',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 				=> 0,
		'Cwd'				=> 0,
		'DateTime'			=> 0,
		'DBI'				=> 0,
		'DBD::mysql'			=> 0,
		'DBIx::Recordset'		=> 0, # deprecate
		'DBIx::Class'			=> 0,
	},
    META_MERGE => {
        resources => {
            bugtracker  =>      'https://bitbucket.org/spek/freeradius-database/issues',
            repository  =>      'https://bitbucket.org/spek/freeradius-database',
        },
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FreeRADIUS-*' },

);
