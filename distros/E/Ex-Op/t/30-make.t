#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

no strict 'refs';

my $outer = 10;

my @accept = (
    [ 'two parameters',          sub { my ($x, $y) = @_; $x + $y } ],
    [ 'one parameter',           sub { my ($x) = @_; $x * 2 } ],
    [ 'no parameters',           sub { 42 } ],
    [ 'a return at the end',     sub { my ($x) = @_; return $x } ],
    [ 'a return in a plain if',  sub { my ($x) = @_; if ($x) { return 1 } 0 } ],
    [ 'a return in a ternary',   sub { my ($x) = @_; return $x ? 1 : 0 } ],
    [ 'or return',               sub { my ($x) = @_; $x or return 0; 1 } ],
    [ 'lexicals in the body',    sub { my ($x) = @_; my $t = $x + 1; my @l = ($t); $l[0] } ],
    [ 'a loop with no return',   sub { my ($n) = @_; my $s = 0; $s += $_ for 1 .. $n; $s } ],
    [ 'next inside its loop',    sub { my ($n) = @_; my $s = 0; for my $i (1 .. $n) { next if $i % 2; $s += $i } $s } ],
    [ 'a closure',               sub { my ($x) = @_; $x + $outer } ],
    [ '$_ and local $_',         sub { my ($x) = @_; local $_ = $x; $_ + 1 } ],
    [ 'sort, grep and map',      sub { my ($x) = @_; my @s = sort { $a <=> $b } grep { $_ } map { $_ * $x } 1, 0, 2; "@s" } ],
    [ 'eval with no return',     sub { my ($x) = @_; my $r = eval { $x + 1 }; $r } ],
    [ 'a sub call with parens',  sub { my ($x) = @_; abs($x) + CORE::length("$x") } ],
);

for my $case (@accept) {
    my ($desc, $code) = @$case;
    my $name = "acc_" . ($desc =~ s/\W+/_/gr);
    ok( Ex::Op::make($name, $code), "accepted: $desc" );
    ok( Ex::Op::is_op($code), "... is_op" );
    is( Ex::Op::why_not($code), undef, '... why_not is undef' );
    is( \&{"main::$name"}, $code, '... installed in the caller' );
}

sub helper { 'h' }

my @decline = (
    [ '$_[0]',                    'it reads @_ after its parameters',      sub { my ($x) = @_; $_[0] } ],
    [ 'shift',                    'it reads @_ after its parameters',      sub { my $x = shift; $x } ],
    [ 'scalar @_',                'it reads @_ after its parameters',      sub { scalar @_ } ],
    [ '"@_"',                     'it reads @_ after its parameters',      sub { "@_" } ],
    [ 'a late binding',           'it reads @_ after its parameters',      sub { my $t = 1; my ($x) = @_; $x } ],
    [ '&helper;',                 'it calls a sub as &name; which passes on @_', sub { &helper; } ],
    [ 'wantarray',                'it calls wantarray',                    sub { wantarray } ],
    [ 'caller',                   'it calls caller',                       sub { caller } ],
    [ 'goto &sub',                'it uses goto',                          sub { goto &helper } ],
    [ 'goto LABEL',               'it uses goto',                          sub { goto L; L: 1 } ],
    [ 'a string eval',            'it uses a string eval',                 sub { eval '1' } ],
    [ 'a return in a for',        'it returns from inside a loop or a block', sub { my ($n) = @_; for (1 .. $n) { return $_ } 0 } ],
    [ 'a return in a while',      'it returns from inside a loop or a block', sub { my ($n) = @_; while ($n) { return 1 } 0 } ],
    [ 'a return in a bare block', 'it returns from inside a loop or a block', sub { my ($n) = @_; { return 1 } } ],
    [ 'a return in eval',         'it returns from inside a loop or a block', sub { my ($n) = @_; eval { return 1 }; 0 } ],
    [ 'a return in grep',         'it returns from inside a loop or a block', sub { my ($n) = @_; grep { return 1 } 1 } ],
    [ 'a return in an if with a my', 'it returns from inside a loop or a block', sub { my ($n) = @_; if ($n) { my $t = 1; return $t } 0 } ],
    [ 'last outside a loop',      'it leaves a loop it is not inside',     sub { my ($n) = @_; no warnings; last; } ],
    [ 'next with a label',        'it leaves a loop it is not inside',     sub { my ($n) = @_; L: for (1) { next L } 1 } ],
    [ 'a slurpy array',           'its parameters end in an array or a hash', sub { my ($x, @rest) = @_; $x } ],
    [ q{assigning to an old lexical}, q{its first statement assigns @_ to something other than new scalars}, sub { ($outer) = @_; $outer } ],
    [ q{pop},                     q{it reads @_ after its parameters},      sub { my ($x) = @_; pop } ],
    [ 'an XSUB',                  'it is not a Perl sub with a body',      \&Ex::Op::is_op ],
);

for my $case (@decline) {
    my ($desc, $why, $code) = @$case;
    my $name = "dec_" . ($desc =~ s/\W+/_/gr);
    ok( !Ex::Op::make($name, $code), "declined: $desc" );
    ok( !Ex::Op::is_op($code), "... not is_op" );
    is( Ex::Op::why_not($code), $why, "... because $why" );
}

SKIP: {
    skip '__SUB__ needs perl 5.16', 1 if $] < 5.016;
    my $code = eval q{ use feature q{current_sub}; sub { my $t = $outer; __SUB__ } } or die $@;
    Ex::Op::make(dec_current_sub => $code);
    is( Ex::Op::why_not($code), 'it uses __SUB__', 'declined: __SUB__' );
}

SKIP: {
    skip 'signatures with argcheck need perl 5.26', 1 if $] < 5.026;
    my $code = eval q{ no warnings; use feature 'signatures'; sub ($x) { $x } } or die $@;
    Ex::Op::make(dec_signature => $code);
    is( Ex::Op::why_not($code), 'it has a signature', 'declined: a signature' );
}

{
    eval q{ sub dec_lv :lvalue { my ($x) = @_; $outer } 1 } or die $@;
    my $code = \&dec_lv;
    Ex::Op::make(dec_lvalue => $code);
    is( Ex::Op::why_not($code), 'it is an lvalue sub', 'declined: an lvalue sub' );
}

is( Ex::Op::why_not(sub { 1 }), 'it was never made an op', 'why_not for a sub never made one' );

{
    package EO::MakeHere;
    ::ok( Ex::Op::make(here => sub { 'here' }), 'make from another package' );
    ::is( EO::MakeHere::here(), 'here', '... installs there' );
    ::ok( Ex::Op::make('EO::Elsewhere::there', sub { 'there' }), 'a qualified name' );
    ::is( EO::Elsewhere::there(), 'there', '... installs where it says' );
}

ok( !eval { Ex::Op::make(x => 'not code'); 1 }, 'make with no code reference' );
like( $@, qr/^Ex::Op::make needs a code reference at /, '... croaks' );
ok( !eval { Ex::Op::make('' => sub { 1 }); 1 }, 'make with an empty name' );
like( $@, qr/^Ex::Op::make needs a name at /, '... croaks' );
ok( !eval { Ex::Op::is_op('x'); 1 }, 'is_op with no code reference' );
like( $@, qr/^Ex::Op::is_op needs a code reference at /, '... croaks' );

{
    my $ok = eval q{
        package EO::Strict;
        use Ex::Op 'strict';
        BEGIN { Ex::Op::make(s_bad => sub { wantarray }) }
        1;
    };
    ok( !$ok, "use Ex::Op 'strict' makes a decline croak" );
    like( $@, qr/^EO::Strict::s_bad cannot be an op: it calls wantarray at /, '... with the name and the reason' );

    $ok = eval q{
        package EO::Strict2;
        use Ex::Op 'strict';
        BEGIN { Ex::Op::make(s_good => sub { my ($x) = @_; $x }) }
        1;
    };
    ok( $ok, '... and an accepted sub is fine' ) or diag $@;
    ok( defined &EO::Strict2::import, "... and 'strict' still installs import" );

    $ok = eval q{
        package EO::Strict3;
        { use Ex::Op 'strict'; }
        BEGIN { Ex::Op::make(s_out => sub { wantarray }) }
        1;
    };
    ok( $ok, "'strict' is lexical: it ends with the block" ) or diag $@;
}

done_testing;
