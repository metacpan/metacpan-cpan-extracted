package MyTest::Tests::May::Iter;

use strict;
use warnings;
use Role::Tiny ();

use parent 'Iterator::Flex::Base';

sub construct {
    my $class = shift;
    $class->construct_from_state( @_ );
}

sub construct_from_state {

    my $class = shift;

    my $x;
    return {
        _name  => 'prev',
        next   => sub { ++$x },
        rewind => sub { ++$x },
        ( defined $_[0] && @{ $_[0] } ? ( _depends => $_[0] ) : () ),
    };
}

__PACKAGE__->_add_roles( qw[
      State::Registry
      Next::Closure
      Rewind::Closure
] );


1;
