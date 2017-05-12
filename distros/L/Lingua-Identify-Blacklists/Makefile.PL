use inc::Module::Install;

name          'Lingua-Identify-Blacklists';
all_from      'lib/Lingua/Identify/Blacklists.pm';

install_script 'bin/blacklist_classifier';
install_share;

requires 'File::ShareDir'           => 0;
requires 'File::Basename'           => 0;
requires 'File::GetLineMaxLength'   => 0;
requires 'Lingua::Identify'         => 0;
requires 'Lingua::Identify::CLD'    => '0.05';


WriteAll;
