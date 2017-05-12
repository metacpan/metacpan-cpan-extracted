require 5.012003;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

name		'Lingua-EN-CMUDict';
all_from	'lib/Lingua/EN/CMUDict.pm';

#requires DB_File and File::ShareDir
requires	'DB_File'		=> 1.818,
		'File::ShareDir'	=> 1.03;

#Don't forget the DB file
install_share;

license		'gpl';

author		'Leigh Metcalf <leigh@fprime.net>';


WriteAll;
