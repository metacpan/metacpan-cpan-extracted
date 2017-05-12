# Errno::AnyString 1.03 t/Foo4.pm
# Test module for Errno::AnyString
# uses a closure to hide away a ref to the real $!

package Foo4;
use strict;
use warnings;

sub new {
    my $bangref = \$!;

    bless {
        Coderef => sub { $$bangref },
    }, shift;
}

sub errno {
    my $self = shift;

    my $num = 0 + $self->{Coderef}->();
    return $num;
}

sub errstr {
    my $self = shift;

    my $str = $self->{Coderef}->();
    return "$str";
}

1;

