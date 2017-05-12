use strict;
use warnings;

use Test::More;

use Devel::StackTrace;

{
    my $trace       = baz();
    my $other_trace = bar();

    $trace->frames( $other_trace->frames );

    my @f;
    while ( my $f = $trace->next_frame ) { push @f, $f; }

    ok( @f == 1, 'only one frame' );

    is(
        $f[0]->subroutine, 'main::bar',
        'First frame subroutine should be main::bar'
    );
}

done_testing();

sub foo {
    return Devel::StackTrace->new( skip_frames => 2 );
}

sub bar {
    foo();
}

sub baz {
    bar();
}
