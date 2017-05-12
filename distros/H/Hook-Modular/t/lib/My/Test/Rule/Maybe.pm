package My::Test::Rule::Maybe;
use warnings;
use strict;
use parent 'Hook::Modular::Rule';

sub dispatch {
    my $self = shift;
    $self->{chance} || 0;
}
1;
