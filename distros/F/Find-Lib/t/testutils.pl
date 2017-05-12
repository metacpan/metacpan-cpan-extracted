use strict;

sub _in_inc {
    my $path = shift;
    my @match = grep { m/$path/ } @INC; 
    return scalar @match;
}

sub in_inc {
    ok _in_inc(@_), "$_[0] is in inc";
}

sub not_in_inc {
    ok ! _in_inc(@_), "$_[0] is NOT in inc";
}

1;
