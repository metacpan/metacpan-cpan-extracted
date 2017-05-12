package testlib::Croak;
use strict;
use warnings;
use Future::Q;
use Carp;

our @CARP_NOT = qw(Future::Q);

sub croak_in_try {
    return Future::Q->try(sub {
        croak "Something is wrong";
    });
}

sub croak_in_fcall {
    return Future::Q->fcall(sub {
        croak "Something is wrong";
    });
}

sub croak_in_then_pending_fulfilled {
    my $f = Future::Q->new;
    my $ret = $f->then(sub {
        croak "Something is wrong";
    });
    return ($ret, $f);
}

sub croak_in_then_fulfilled {
    my ($child, $parent) = croak_in_then_pending_fulfilled();
    $parent->fulfill("OK");
    return $child;
}

sub croak_in_then_pending_rejected {
    my $f = Future::Q->new;
    my $ret = $f->then(undef, sub {
        croak "Something is wrong";
    });
    return ($ret, $f);
}

sub croak_in_then_rejected {
    my ($child, $parent) = croak_in_then_pending_rejected();
    $parent->reject("NG");
    return $child;
}

sub croak_in_catch_pending {
    my $f = Future::Q->new;
    my $ret = $f->catch(sub {
        croak "Something is wrong";
    });
    return ($ret, $f);
}

sub croak_in_catch {
    my ($child, $parent) = croak_in_catch_pending();
    $parent->reject("NG");
    return $child;
}

1;

