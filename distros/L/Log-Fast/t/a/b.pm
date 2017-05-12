package a::b;
use warnings;
use strict;

my $LOG = Log::Fast->global();


sub B {
    $LOG->ERR('in a::b::B');
}

sub call {
    my $func = shift;
    no strict 'refs';
    $func->(@_);
}


1;
