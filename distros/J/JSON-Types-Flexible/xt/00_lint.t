use strict;
use warnings;
use utf8;

use Test::Perl::Critic -profile => 'xt/perlcriticrc';

all_critic_ok('lib', 't', 'xt');
