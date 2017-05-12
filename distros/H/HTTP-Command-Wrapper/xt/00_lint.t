use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;

eval {
    require Test::Perl::Critic;
    Test::Perl::Critic->import( -profile => 'xt/perlcriticrc', -severity => 1 );
};

all_critic_ok('lib', 't', 'xt');
