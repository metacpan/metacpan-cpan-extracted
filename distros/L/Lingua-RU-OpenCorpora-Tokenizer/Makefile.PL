use inc::Module::Install;

all_from 'lib/Lingua/RU/OpenCorpora/Tokenizer.pm';
readme_from 'lib/Lingua/RU/OpenCorpora/Tokenizer.pm';

requires 'parent';
requires 'LWP::UserAgent';
requires 'File::ShareDir';
requires 'List::MoreUtils';
requires 'IO::Uncompress::Gunzip';

test_requires 'Test::Deep';
test_requires 'Test::Exception';

install_script 'opencorpora-update-tokenizer';
install_share  'share';

WriteAll;
