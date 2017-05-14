#!/usr/bin/perl -w

use warnings;
use strict;

use inc::Module::Install;

name			'Hopkins';
author			'Mike Eldridge <diz@cpan.org>';
license			'perl';
version_from	'lib/Hopkins.pm';

# supporting classes
requires 'Class::Accessor::Fast'		=> '0.31';
requires 'List::Object'					=> '0.01';
requires 'Tie::IxHash'					=> '1.21';
requires 'Cache::FileCache'				=> 0;
requires 'Data::UUID'					=> 0;
requires 'JSON'							=> '2.16';
requires 'LWP::UserAgent'				=> '5.833';
requires 'version'						=> '0.77';

# date manipulation and testing
requires 'DateTime'						=> '0.37';
requires 'DateTime::Event::MultiCron'	=> '0.01';
requires 'DateTime::Format::ISO8601'	=> '0.06';
requires 'DateTime::Set'				=> '0.25';

# configuration and logging
requires 'File::Monitor'				=> '0.10';
requires 'Log::Log4perl'				=> '1.12';
requires 'XML::LibXML'					=> '1.69';
requires 'XML::Simple'					=> '2.18';

# DBI/POE infrastructure
requires 'DBIx::Class'					=> '0.08103';
requires 'POE'							=> '1.005';
requires 'POE::API::Peek'				=> '1.34';
requires 'POE::Component::JobQueue'		=> '0.55';
requires 'POE::Wheel::Run'				=> '1.2179';
requires 'YAML::XS'						=> '0.32';

# required for the test suite
test_requires 'Class::MOP';
test_requires 'Directory::Scratch';
test_requires 'FindBin';
test_requires 'Template';
test_requires 'Test::MockObject';
test_requires 'POE::API::Peek';

install_script 'bin/hopjobd';

#auto_install;
WriteAll;

