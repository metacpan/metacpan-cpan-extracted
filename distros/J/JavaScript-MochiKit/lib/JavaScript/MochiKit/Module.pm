package JavaScript::MochiKit::Module;

use strict;
use base qw[ JavaScript::MochiKit::Accessor ];

__PACKAGE__->mk_accessors(qw[ name required javascript_definition ]);

sub javascript_loaded {
    return defined shift->javascript_definition
      and shift->javascript_definition ne '';
}

1;
