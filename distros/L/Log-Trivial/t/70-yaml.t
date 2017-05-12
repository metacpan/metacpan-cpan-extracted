# $Id: 70-yaml.t,v 1.3 2007-08-20 15:43:40 adam Exp $

use strict;
use Test::More;

BEGIN {
    eval ' use YAML; ';
    if ($@) {
        plan( skip_all => 'YAML not installed.' );
    }
    else {
        plan( tests => 1 );
    }
};

ok(YAML::LoadFile('./META.yml'),             'Is the META.yml valid?');
