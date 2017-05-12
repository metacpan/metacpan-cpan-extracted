package FormValidator::LazyWay::Fix::URI;

use strict;
use warnings;
use URI;

sub format {
    my $text = shift;

    return URI->new($text);
}

1;
