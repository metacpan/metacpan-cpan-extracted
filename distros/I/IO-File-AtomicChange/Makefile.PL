use inc::Module::Install;

name        'IO-File-AtomicChange';
all_from    'lib/IO/File/AtomicChange.pm';
readme_from 'lib/IO/File/AtomicChange.pm';
license     'perl';
auto_set_repository;
auto_provides;

cpanfile;
WriteAll;
