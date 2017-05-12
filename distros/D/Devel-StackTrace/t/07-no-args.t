use strict;
use warnings;

use Test::More;

use Devel::StackTrace;

{
    my $trace = foo( 1, 2 );
    is_deeply(
        [ map { [ $_->args() ] } $trace->frames() ],
        [
            ['Devel::StackTrace'],
            [ 3, 4 ],
            [ 1, 2 ],
        ],
        'trace includes args'
    );

    $trace = foo( 0, 2 );
    is_deeply(
        [ map { [ $_->args() ] } $trace->frames() ],
        [
            [],
            [],
            [],
        ],
        'trace does not include args'
    );

}

done_testing();

sub foo {
    $_[0] ? bar( 3, 4 ) : baz( 3, 4 );
}

sub bar {
    return Devel::StackTrace->new();
}

sub baz {
    return Devel::StackTrace->new( no_args => 1 );
}
