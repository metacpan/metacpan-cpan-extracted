# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name		'HoneyClient-Util';
license		'gpl';
perl_version	'5.006';
author		'MITRE Honeyclient Project <honeyclient@mitre.org>';
version		'0.98';
clean_files	't/';

requires	'Carp' => '0';
requires	'Data::Dumper' => '0';
requires	'Log::Dispatch::Syslog' => '0';
requires	'Log::Log4perl' => '0';
requires	'SOAP::Lite' => '0.67';
requires	'SOAP::Transport::HTTP' => '0';
requires	'Sys::Syslog' => '0';
requires	'XML::Tidy' => '0';
requires	'XML::XPath' => '0';

no_index	'directory' => 'etc';
no_index	'directory' => 'inc';
no_index	'directory' => 'thirdparty';

auto_install;
WriteAll;
