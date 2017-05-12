use warnings;
use strict;
use inc::Module::Install;

use 5.006;

#eval {};
#BEGIN {};

name           'Kephra';
license        'gpl_2';
author         'Herbert Breunung';
homepage       'http://kephra.sourceforge.net/';
bugtracker     'http://sourceforge.net/tracker/?group_id=169747&atid=851590';


all_from       'lib/Kephra.pm';
requires       'Cwd';
requires       'Encode::Guess';
requires       'File::UserConfig';
requires       'Config::General'         => 2.40;
requires       'YAML::Tiny'              => 0.31;
requires       'Text::Wrap';
requires       'POSIX';
requires       'Wx'                      => 0.94;
requires       'Wx::Perl::ProcessStream' => 0.25;
build_requires 'Test::More'              => 0.47;
build_requires 'Test::Script'            => 0.01;
build_requires 'Test::NoWarnings';
build_requires 'Test::Exception';

no_index 'directory' => qw{ t xt share inc };

install_share  'share';
install_script 'bin/kephra';

WriteAll;
