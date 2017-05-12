use inc::Module::Install;

name     'Image-WordCloud';
all_from 'lib/Image/WordCloud.pm';
author   q{Brian Hann <bhann@cpan.org>};
license  'perl';

resources
	bugtracker 'https://github.com/c0bra/image-wordcloud-perl/issues';
	repository 'https://github.com/c0bra/image-wordcloud-perl';

test_requires 'Test::More';
test_requires 'Test::Fatal';
test_requires 'Test::Warn';

requires 'Params::Validate';
requires 'List::Util';
requires 'File::Spec';
requires 'File::Find::Rule';
requires 'File::ShareDir';
requires 'GD';
requires 'GD::Text::Align';
requires 'Color::Scheme';
requires 'Math::PlanePath::TheodorusSpiral';

install_share;

auto_install;

WriteAll;

