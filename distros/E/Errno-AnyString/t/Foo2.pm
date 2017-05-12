# Errno::AnyString 1.03 t/Foo2.pm
# Test module for Errno::AnyString

package Foo2;
use strict;
use warnings;

use English;

sub new {
    bless {}, shift;
}

sub errno {
    my $num = 0 + $OS_ERROR;
    return $num;
}

sub errstr {
    my $str = "$OS_ERROR";
    return $str;
}

1;

