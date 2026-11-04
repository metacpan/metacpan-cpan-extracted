#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

BEGIN {
    Ex::Op::make(ret => sub { my ($x) = @_; return $x + 1 if $x; 0 });
    Ex::Op::make(warns => sub { my ($x) = @_; my $y = $x . '!'; $y });
    Ex::Op::make(keep_ref => sub { my ($x) = @_; push @main::kept, \$x; $x });
}

sub collect {
    my $a = keep_ref(1);
    my $b = keep_ref(2);
    my $c = keep_ref(3);
    return ($a, $b, $c);
}

{
    is_deeply( [collect()], [1, 2, 3], 'a parameter kept by reference is returned as usual' );
    is_deeply( [ map { $$_ } @main::kept ], [1, 2, 3], '... and each reference keeps the value it was given, the call having let it go' );
}

my $top = ret(1);
is( $top, 2, 'a call at the top level of the file' );
is( ret(0), 0, '... and one that does not reach its return' );

{
    my $ref = \&ret;
    is( $ref->(1), 2, 'a call through a reference runs the body with its return as an ordinary sub' );
    is( &ret(2), 3, '... and so does a call with &' );
}

SKIP: {
    skip 'lexical subs need perl 5.18', 2 if $] < 5.018;
    my $v = eval q{
        use feature 'lexical_subs';
        no warnings;
        my sub lex { my ($x) = @_; $x * 2 }
        BEGIN { Ex::Op::make('lex_copy', \&lex) }
        lex(21);
    };
    is( $@, '', 'a lexical sub can be made an op' );
    is( $v, 42, '... and a call by its lexical name, which no call checker sees, is an ordinary call' );
}

{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $r = eval { { warns(undef) } };
    is( $r, '!', 'a call in a bare block inside an eval block' );
    like( $w[0], qr/uninitialized value \$x/, '... names the parameter in its warning' );
    @w = ();
    $r = eval q{ { warns(undef) } };
    is( $r, '!', 'a call in a bare block inside a string eval' );
    like( $w[0], qr/uninitialized value \$x/, '... names the parameter too' );
    @w = ();
    my $m = 'a' =~ /(?{ warns(undef) })/ ? 1 : 0;
    is( $m, 1, 'a call inside a regex code block' );
    like( $w[0], qr/uninitialized value \$x/, '... names the parameter as well' );
}

done_testing;
