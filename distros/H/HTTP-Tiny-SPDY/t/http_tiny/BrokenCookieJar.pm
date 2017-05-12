package t::http_tiny::BrokenCookieJar;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {} => $class;
}

package t::http_tiny::BrokenCookieJar2;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {} => $class;
}

sub add {
}

1;
