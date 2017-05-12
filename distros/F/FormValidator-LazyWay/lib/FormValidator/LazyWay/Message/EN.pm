package FormValidator::LazyWay::Message::EN;

use strict;
use warnings;

sub invalid {
    return '__field__ supports __rule__ .';
}

sub missing {
    return '__field__ is missing.';
}

1;

