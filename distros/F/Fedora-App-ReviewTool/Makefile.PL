use inc::Module::Install;

name     'Fedora-App-ReviewTool';
all_from 'lib/Fedora/App/ReviewTool.pm';
author   'Chris Weyl <cweyl@alumni.drew.edu>';

requires 'autodie';
requires 'namespace::clean';

requires 'MooseX::App::Cmd';

requires 'Moose';
requires 'Moose::Role';
requires 'Moose::Util::TypeConstraints';
#requires 'MooseX::StrictConstructor';
requires 'MooseX::Traits::Attribute::CascadeClear';
requires 'MooseX::Traits::Attribute::CascadeClearMaster';
requires 'MooseX::Types::DateTime';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types::URI';
requires 'MooseX::Role::XMLRPC::Client';
requires 'MooseX::Workers' => '0.04';

# reviewtool
requires 'Config::Tiny';
requires 'Crypt::OpenSSL::X509';
requires 'Data::Section';
requires 'Digest::SHA1';
requires 'Fedora::Bugzilla' => '0.10';
requires 'File::Slurp';
requires 'File::Temp';
requires 'FindBin';
requires 'IO::Prompt';
requires 'IPC::System::Simple';
requires 'Path::Class';
requires 'Readonly';
requires 'LWP::Simple';
requires 'Template';
requires 'Term::Completion';
requires 'Term::ProgressBar';
requires 'Term::Size';
requires 'Text::SimpleTable';
requires 'URI::Fetch';
requires 'URI::Find';

requires_external_bin 'koji';
requires_external_bin 'scp';
requires_external_bin 'rpm2cpio';
requires_external_bin 'cpio';
requires_external_bin 'cvs';

test_requires 'Test::More';

install_script 'bin/reviewtool';

no_index directory => 'xt';

extra_tests;
auto_provides;
auto_install;

WriteAll;

