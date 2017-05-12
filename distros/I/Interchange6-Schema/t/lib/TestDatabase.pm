package TestDatabase;

use Moo;
extends 'Test::Roo';

around 'run_me' => sub {
    my $orig = shift;
    my $ret = $orig->(@_);
    return $ret;
};

1;
