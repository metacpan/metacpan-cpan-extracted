#
# This file is part of Exception-Stringy
#
# This software is Copyright (c) 2014 by Damien Krotkine.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
use strict;
use warnings;

use Exception::Stringy;
Exception::Stringy->declare_exceptions(
     'Some::Exception' => {
          fields => [ 'field1', 'field2' ],
          throw_alias  => 'throw_exception',
     },
);
1;

