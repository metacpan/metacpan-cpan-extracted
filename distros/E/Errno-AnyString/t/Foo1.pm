# Errno::AnyString 1.03 t/Foo1.pm
# Test module for Errno::AnyString

package Foo1;
use strict;
use warnings;

sub new {
    bless {}, shift;
}

sub errno {
    my $num = 0 + $!;
    return $num;
}

sub errstr {
    my $str = "$!";
    return $str;
}

1;

