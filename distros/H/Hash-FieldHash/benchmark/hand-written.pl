#!perl -w
use strict;
use warnings;
use Benchmark qw(:all);
use Hash::FieldHash;
{
    package ByHand;
    use Scalar::Util qw(refaddr);
    my %foo_of;
    my %bar_of;
    my %baz_of;
    sub new {
        my($class, $a, $b, $c) = @_;
        my $self = bless {}, $class;
        $foo_of{refaddr $self} = $a;
        $bar_of{refaddr $self} = $b;
        $baz_of{refaddr $self} = $c;
        return $self;
    }
    sub DESTROY {
        my($self) = @_;
        delete $foo_of{refaddr $self};
        delete $bar_of{refaddr $self};
        delete $baz_of{refaddr $self};
    }
}
{
    package ByFH;
    use Hash::FieldHash qw(fieldhashes);
    fieldhashes\my(%foo_of, %bar_of, %baz_of);
    sub new {
        my($class, $a, $b, $c) = @_;
        my $self = bless {}, $class;
        $foo_of{$self} = $a;
        $bar_of{$self} = $b;
        $baz_of{$self} = $c;
        return $self;
    }
}

cmpthese timethese -1, {
    ByHand => sub {
        for(1 .. 100) {
            my $o = ByHand->new(10, 20, 30);
        }
    },
    ByFieldHash => sub {
        for(1 .. 100) {
            my $o = ByFH->new(10, 20, 30);
        }
    },
};


