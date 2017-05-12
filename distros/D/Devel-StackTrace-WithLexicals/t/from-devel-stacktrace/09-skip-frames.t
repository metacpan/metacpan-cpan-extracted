use strict;
use warnings;

use Test::More;

use Devel::StackTrace::WithLexicals;

{
    my $trace = baz();
    my @f;
    while ( my $f = $trace->next_frame ) { push @f, $f; }

    my $cnt = scalar @f;
    is(
        $cnt, 2,
        "Trace should have 2 frames"
    );

    is(
        $f[0]->subroutine, 'main::bar',
        "First frame subroutine should be main::bar"
    );
    is_deeply(
        [sort keys $f[0]->lexicals], ['$baz_var'],
        'First frame lexical should be $baz_var'
    );
    is(
        $f[1]->subroutine, 'main::baz',
        "Second frame subroutine should be main::baz"
    );
    is_deeply(
        [sort keys $f[1]->lexicals], [],
        'Second frame should have no lexicals'
    );
}

done_testing();

sub foo {
    my $foo_var=1;
    return Devel::StackTrace::WithLexicals->new( skip_frames => 2 );
}

sub bar {
    my $bar_var=1;
    foo();
}

sub baz {
    my $baz_var=1;
    bar();
}
