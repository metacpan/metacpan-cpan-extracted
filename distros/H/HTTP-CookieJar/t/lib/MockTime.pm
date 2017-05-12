use strict;
use warnings;

package MockTime;

my ( $_original_time, $_offset );

sub time () {
    return $_original_time + $_offset;
}

sub offset {
    my ( $class, $offset ) = @_;
    $_offset = $offset;
}

BEGIN {
    ( $_original_time, $_offset ) = ( CORE::time(), 0 );
    *CORE::GLOBAL::time = \&time;
}

1;
