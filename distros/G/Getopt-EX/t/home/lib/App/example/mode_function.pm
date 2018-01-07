package App::example::mode_function;
use strict;
use warnings;

sub initialize {
    my $mod = shift;
    # $mod->mode(function => 1);
}

sub bye {
    qw(hasta la vista);
}

1;

__DATA__

mode function

option --bye &bye
