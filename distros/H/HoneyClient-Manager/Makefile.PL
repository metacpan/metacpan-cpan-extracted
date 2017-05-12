# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name		'HoneyClient-Manager';
license		'gpl';
perl_version	'5.006';
author		'MITRE Honeyclient Project <honeyclient@mitre.org>';
all_from		'lib/HoneyClient/Manager.pm';
clean_files	't/';

requires	'Carp' => '0';
requires	'Config' => '0';
requires	'Config::General' => '0';
requires	'Data::Dumper' => '0';
requires	'DateTime::HiRes' => '0';
requires	'Digest::MD5' => '0';
requires	'English' => '0';
requires	'ExtUtils::MakeMaker' => '0';
requires	'Fcntl' => '0';
requires	'File::Basename' => '0';
requires	'File::Copy' => '0';
requires	'File::Copy::Recursive' => '0';
requires	'File::stat' => '0';
requires	'FileHandle' => '0';
requires	'HoneyClient::Util::Config' => '0';
requires	'HoneyClient::Util::SOAP' => '0';
requires	'IO::File' => '0';
requires	'IPTables::IPv4' => '0';
requires	'Log::Log4perl' => '0';
requires	'MIME::Base64' => '0';
requires	'Net::DNS::Resolver' => '0';
requires	'POSIX' => '0';
requires	'Proc::ProcessTable' => '0';
requires	'Storable' => '0';
requires	'Thread::Queue' => '0';
requires	'Thread::Semaphore' => '0';
requires	'Tie::File' => '0';
requires	'Time::HiRes' => '0';
requires	'VMware::VmPerl' => '0';
requires	'VMware::VmPerl::ConnectParams' => '0';
requires	'VMware::VmPerl::Question' => '0';
requires	'VMware::VmPerl::Server' => '0';
requires	'VMware::VmPerl::VM' => '0';
requires	'sigtrap' => '0';
requires	'threads' => '0';
requires	'threads::shared' => '0';

no_index	'directory' => 'etc';
no_index	'directory' => 'inc';
no_index	'directory' => 'thirdparty';

auto_install;
WriteAll;
