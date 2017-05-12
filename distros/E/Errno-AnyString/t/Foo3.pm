# Errno::AnyString 1.03 t/Foo3.pm
# Test module for Errno::AnyString

package Foo3;
use strict;
use warnings;

use English;

sub new {
    bless {}, shift;
}

sub errno {
    my $num = 0 + $ERRNO;
    return $num;
}

sub errstr {
    my $str = "$ERRNO";
    return $str;
}

1;

