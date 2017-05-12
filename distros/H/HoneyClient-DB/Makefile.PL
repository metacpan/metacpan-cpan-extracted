# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name		'HoneyClient-DB';
license		'gpl';
perl_version	'5.006';
author		'MITRE Honeyclient Project <honeyclient@mitre.org>';
all_from		'lib/HoneyClient/DB.pm';
clean_files	't/';

requires	'Data::Dumper' => '0';
requires	'Digest::MD5' => '0';
requires	'base' => '0';

no_index	'directory' => 'etc';
no_index	'directory' => 'inc';
no_index	'directory' => 'thirdparty';

auto_install;
WriteAll;
