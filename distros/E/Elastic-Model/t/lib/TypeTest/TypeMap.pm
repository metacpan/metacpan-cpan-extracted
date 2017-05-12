package TypeTest::TypeMap;

use strict;
use warnings;

use Carp;

use Elastic::Model::TypeMap::Base qw(
    Elastic::Model::TypeMap::Default
    :all
);

#===================================
has_type 'CustomClass' =>
#===================================
    deflate_via {
    sub { $_[0] * 4 }
    },
    inflate_via {
    sub { $_[0] / 4 }
    },
    map_via { type => 'integer' };

#===================================
has_type 'BadMapping' =>
#===================================
    map_via {'xyz'};

1;
