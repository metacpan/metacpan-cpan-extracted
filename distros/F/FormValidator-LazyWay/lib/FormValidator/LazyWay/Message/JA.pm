package FormValidator::LazyWay::Message::JA;

use strict;
use warnings;
use utf8;

sub invalid {
    return '__field__には、__rule__が使用できます。';
}

sub missing {
    return '__field__が空欄です。';
}

1;
