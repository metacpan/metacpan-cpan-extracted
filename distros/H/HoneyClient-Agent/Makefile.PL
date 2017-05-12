# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name		'HoneyClient-Agent';
license		'gpl';
perl_version	'5.006';
author		'MITRE Honeyclient Project <honeyclient@mitre.org>';
all_from		'lib/HoneyClient/Agent.pm';
clean_files	't/';

requires	'Algorithm::Diff' => '0';
requires	'Carp' => '0';
requires	'Config' => '0';
requires	'Data::Compare' => '0';
requires	'Data::Diff' => '0';
requires	'Data::Dumper' => '0';
requires	'Data::Structure::Util' => '0';
requires	'Data::Validate::URI' => '0';
requires	'DateTime' => '0';
requires	'DateTime::HiRes' => '0';
requires	'Digest::MD5' => '0';
requires	'Digest::SHA' => '0';
requires	'ExtUtils::MakeMaker' => '0';
requires	'Fcntl' => '0';
requires	'File::Basename' => '0';
requires	'File::Find' => '0';
requires	'File::Temp' => '0';
requires	'File::Type' => '0';
requires	'Filesys::CygwinPaths' => '0';
requires	'HTML::LinkExtor' => '0';
requires	'HTML::TokeParser' => '0';
requires	'HTTP::Request::Common' => '0';
requires	'HoneyClient::Util::Config' => '0';
requires	'HoneyClient::Util::SOAP' => '0';
requires	'IO::File' => '0';
requires	'IO::Handle' => '0';
requires	'LWP::UserAgent' => '0';
requires	'Log::Log4perl' => '0';
requires	'MIME::Base64' => '0';
requires	'POSIX' => '0';
requires	'Parse::Yapp::Driver' => '0';
requires	'Search::Binary' => '0';
requires	'Storable' => '0';
requires	'Term::ProgressBar' => '0';
requires	'Test::Exception' => '0';
requires	'Thread::Queue' => '0';
requires	'Thread::Semaphore' => '0';
requires	'Time::HiRes' => '0';
requires	'URI::URL' => '0';
requires	'Win32::Job' => '0';
requires	'sigtrap' => '0';
requires	'threads' => '0';
requires	'threads::shared' => '0';
requires	'vars' => '0';

no_index	'directory' => 'etc';
no_index	'directory' => 'inc';
no_index	'directory' => 'thirdparty';

auto_install;
WriteAll;
