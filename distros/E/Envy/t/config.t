# -*-perl-*-

use strict;
use Test; plan test => 2;

delete $ENV{PERL5PREFIX};

$ENV{ENVY_PATH} = join(':', '/my/site/path/bin', '/my/custom/path/bin');
$ENV{ENVY_DIMENSION} = join(':', 'First,qsg','objstore,objstore');

require './DefaultConf.pm';

package Envy::DefaultConf;
use vars qw($startup @path);
use Test;

ok join(':', @path), $ENV{ENVY_PATH}, $@;
ok $startup, 'qsg';

