use strict;
use warnings;

use Test::More;

use Devel::StackTrace;

{
    my $trace = baz(2);
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

{
    for my $i ( 1 .. 6 ) {
        my $trace = baz($i);
        like(
            $trace->as_string,
            qr/trace message/,
            "stringified trace includes message when skipping $i frame(s)"
        );
    }
}

done_testing();

sub foo {
    return Devel::StackTrace->new(
        message     => 'trace message',
        skip_frames => shift,
    );
}

sub bar {
    foo(@_);
}

sub baz {
    bar(@_);
}
