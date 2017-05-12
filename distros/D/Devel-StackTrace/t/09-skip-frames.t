use strict;
use warnings;

use Test::More;

use Devel::StackTrace;

{
    my $trace = baz();
    my @f;
    while ( my $f = $trace->next_frame ) { push @f, $f; }

    my $cnt = scalar @f;
    is(
        $cnt, 2,
        'Trace should have 2 frames'
    );

    is(
        $f[0]->subroutine, 'main::bar',
        'First frame subroutine should be main::bar'
    );
    is(
        $f[1]->subroutine, 'main::baz',
        'Second frame subroutine should be main::baz'
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
