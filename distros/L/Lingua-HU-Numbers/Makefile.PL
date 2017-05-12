use strict;
use warnings;
use inc::Module::Install;
name            'Lingua-HU-Numbers';
all_from        'lib/Lingua/HU/Numbers.pm';
requires        'Carp'              => 0;
build_requires  'Test::More'        => '0.42';
author          'Bálint Szilakszi <szbalint@cpan.org>';
license		'perl';
perl_version	'5.006';

sign; WriteAll;
