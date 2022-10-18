use inc::Module::Install;
name 'Feed-Find';
all_from 'lib/Feed/Find.pm';
readme_from 'lib/Feed/Find.pm';

requires 'Class::ErrorHandler';
requires 'LWP';
requires 'HTML::Parser';
requires 'URI';

test_requires 'Test::More';
test_requires 'Test::LWP::UserAgent';

author_tests('xt');
auto_set_repository;
githubmeta;
makemaker_args(
  META_MERGE => {
    resources => {
      bugtracker => {
        web => 'https://github.com/davorg/File-Find/issues',
      },
    },
  },
);
WriteAll;
