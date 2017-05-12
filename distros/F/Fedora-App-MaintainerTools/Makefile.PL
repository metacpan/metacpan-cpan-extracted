use inc::Module::Install;

githubmeta;

name     'Fedora-App-MaintainerTools';
all_from 'lib/Fedora/App/MaintainerTools.pm';
author   'Chris Weyl <cweyl@alumni.drew.edu>';
license  'perl';

requires_external_bin 'rpm';
requires_external_bin 'createrepo';

requires 'autodie';
requires 'namespace::clean';

# silent autodie dep
requires 'IPC::System::Simple';

# min version for native traits
requires 'Moose' => '0.90';
requires 'MooseX::App::Cmd';
requires 'MooseX::AttributeHelpers';
requires 'MooseX::Log::Log4perl';
requires 'MooseX::Traits' => '0.08';
requires 'MooseX::Types';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types::URI';

requires 'CPANPLUS::Backend';
requires 'Data::TreeDumper';
requires 'DateTime';
requires 'File::Copy';
requires 'File::Slurp';
requires 'List::MoreUtils';
requires 'Module::CoreList';
requires 'Path::Class';
requires 'RPM::Spec' => '0.04';
requires 'RPM::VersionSort' => '1.00';
requires 'YAML::Tiny';
requires 'Pod::POM';
requires 'Pod::POM::View::Text';
requires 'Software::LicenseUtils';

# metamuncher
requires 'JSON';

# for ftbfs, etc
requires 'Fedora::Bugzilla' => '0.13';

test_requires 'Test::More';

install_script 'scripts/maintainertool';
install_share;

extra_tests;
auto_provides;
auto_install;
write_mymeta_json;

WriteAll;

