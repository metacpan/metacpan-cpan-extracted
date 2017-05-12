package TypeTest::Structured;

use Elastic::Doc;
use MooseX::Types -declare => ['Bar'];
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);

#===================================
has 'tuple_attr' => (
#===================================
    is  => 'ro',
    isa => Tuple [ Str, Int ],
);

#===================================
has 'tuple_optional_attr' => (
#===================================
    is  => 'ro',
    isa => Tuple [ Str, Optional [Int] ],
);

#===================================
has 'tuple_empty_attr' => (
#===================================
    is  => 'ro',
    isa => Tuple [],
);

#===================================
has 'tuple_blank_attr' => (
#===================================
    is  => 'ro',
    isa => Tuple,
);

#===================================
has 'tuple_bad_attr' => (
#===================================
    is  => 'ro',
    isa => Tuple [Bar],
);

#===================================
has 'dict_attr' => (
#===================================
    is  => 'ro',
    isa => Dict [ str => Str, int => Int ]
);

#===================================
has 'dict_optional_attr' => (
#===================================
    is  => 'ro',
    isa => Dict [ str => Optional [Str], int => Int ]
);

#===================================
has 'dict_empty_attr' => (
#===================================
    is  => 'ro',
    isa => Dict []
);

#===================================
has 'dict_blank_attr' => (
#===================================
    is  => 'ro',
    isa => Dict
);

#===================================
has 'dict_bad_attr' => (
#===================================
    is  => 'ro',
    isa => Dict [ str => Bar ]
);

#===================================
has 'map_attr' => (
#===================================
    is  => 'ro',
    isa => Map [ Int, Str ],
);

#===================================
has 'map_empty_attr' => (
#===================================
    is  => 'ro',
    isa => Map [],
);

#===================================
has 'map_blank_attr' => (
#===================================
    is  => 'ro',
    isa => Map,
);

#===================================
has 'map_bad_attr' => (
#===================================
    is  => 'ro',
    isa => Map [ Int => Bar ],
);

#===================================
has 'optional_attr' => (
#===================================
    is  => 'ro',
    isa => Optional [Int],
);

#===================================
has 'optional_blank_attr' => (
#===================================
    is  => 'ro',
    isa => Optional,
);

#===================================
has 'optional_bad_attr' => (
#===================================
    is  => 'ro',
    isa => Optional [Bar],
);

#===================================
has 'combo_attr' => (
#===================================
    is  => 'ro',
    isa => Dict [
        str  => Str,
        dict => Dict [ int => Int, str => Optional [Str] ],
        'map' => Optional [ Map [ Str => Int ] ],
        tuple => Tuple [ Int, Optional [Str] ]
    ]
);

no Elastic::Doc;

1;

