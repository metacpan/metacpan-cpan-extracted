package a;
use warnings;
use strict;

my $LOG = Log::Fast->global();


sub A {
    $LOG->ERR('in a::A');
}

sub call {
    my $func = shift;
    no strict 'refs';
    $func->(@_);
}


1;
