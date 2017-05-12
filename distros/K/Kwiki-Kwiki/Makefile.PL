use inc::Module::Install;

name            'Kwiki-Kwiki';
license         'perl';
all_from        'lib/Kwiki/Kwiki.pm';

requires
    IO::All => 0.30,
    Archive::Tar => 0;

requires_external_bin 'svn' => 0;

install_script 'bin/kk';

WriteAll;
