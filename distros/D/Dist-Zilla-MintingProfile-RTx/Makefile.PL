use inc::Module::Install;

name 'Dist-Zilla-MintingProfile-RTx';
all_from 'lib/Dist/Zilla/MintingProfile/RTx.pm';
readme_from 'lib/Dist/Zilla/MintingProfile/RTx.pm';
license  'gplv2';
install_share 'module' => 'Dist::Zilla::MintingProfile::RTx', 'profiles';

requires 'Dist::Zilla';
requires 'Module::Install::RTx', 0.34_04;
requires 'Module::Install::ReadmeFromPod';

WriteAll;
