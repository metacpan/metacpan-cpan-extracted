package Logic::Relational::StdLib;

use v5.38;
use experimental 'signatures';
use Logic::Relational      qw(variable call all guard);
use Logic::Relational::DSL qw(rest is_goal true_goal);

=head1 NAME

Logic::Relational::StdLib - Standard Relational Logic Library.

=cut

sub export_to_program ($program) {
    return if $program->{_has_stdlib_exported}++;

    # 1. append(L1, L2, Res)
    my $l     = variable('L');
    my $h     = variable('H');
    my $t     = variable('T');
    my $l2    = variable('L2');
    my $out_t = variable('OutT');

    $program->fact(append => [], $l, $l);
    $program->rule(
        head => call(append => [$h, rest($t)], $l2, [$h, rest($out_t)]),
        body => call(append => $t,             $l2, $out_t)
    );

    # 2. member(X, List)
    my $mx    = variable('X');
    my $my    = variable('Y');
    my $mrest = variable('Rest');

    $program->fact(member => $mx, [$mx, rest($mrest)]);
    $program->rule(
        head => call(member => $mx, [$my, rest($mrest)]),
        body => call(member => $mx, $mrest)
    );

    # 2b. not_member(X, List)
    my $nmx    = variable('X');
    my $nmy    = variable('Y');
    my $nmrest = variable('Rest');

    $program->fact(not_member => $nmx, []);
    $program->rule(
        head => call(not_member => $nmx, [$nmy, rest($nmrest)]),
        body => all(
            Logic::Relational::Goal::Not->new(Logic::Relational::Goal::Unify->new($nmx, $nmy)),
            call(not_member => $nmx, $nmrest)
        )
    );

    # 3. length(List, Len)
    my $lh    = variable('H');
    my $lt    = variable('T');
    my $llen  = variable('Len');
    my $ltlen = variable('TLen');

    $program->fact(list_length => [], 0);
    $program->fact(length      => [], 0);

    $program->rule(
        head => call(list_length => [$lh, rest($lt)], $llen),
        body => all(
            call(list_length => $lt, $ltlen),
            is_goal($llen, [$ltlen], sub ($val) {return $val + 1})
        )
    );
    $program->rule(
        head => call(length => [$lh, rest($lt)], $llen),
        body => all(
            call(length => $lt, $ltlen), is_goal($llen, [$ltlen], sub ($val) {return $val + 1})
        )
    );

    # 4. reverse(List, Rev)
    my $rl   = variable('L');
    my $rrev = variable('Rev');
    my $rh   = variable('H');
    my $rt   = variable('T');
    my $racc = variable('Acc');

    $program->rule(
        head => call(reverse_list => $rl, $rrev),
        body => call(reverse_acc  => $rl, [], $rrev)
    );
    $program->rule(
        head => call(reverse     => $rl, $rrev),
        body => call(reverse_acc => $rl, [], $rrev)
    );
    $program->fact(reverse_acc => [], $racc, $racc);
    $program->rule(
        head => call(reverse_acc => [$rh, rest($rt)], $racc,              $rrev),
        body => call(reverse_acc => $rt,              [$rh, rest($racc)], $rrev)
    );

    # 5. select(X, List, Rest)
    my $sx  = variable('X');
    my $sy  = variable('Y');
    my $sxs = variable('Xs');
    my $sys = variable('Ys');
    my $szs = variable('Zs');

    $program->fact(select => $sx, [$sx, rest($sxs)], $sxs);
    $program->rule(
        head => call(select => $sx, [$sy, rest($sys)], [$sy, rest($szs)]),
        body => call(select => $sx, $sys,              $szs)
    );

    # 6. permutation(List, Perm)
    my $px  = variable('X');
    my $pxs = variable('Xs');
    my $pys = variable('Ys');
    my $pzs = variable('Zs');

    $program->fact(permutation => [], []);
    $program->rule(
        head => call(permutation => [$px, rest($pxs)], $pzs),
        body => all(call(permutation => $pxs, $pys), call(select => $px, $pzs, $pys))
    );

    # 7. succ(X, Y)
    my $sx_val = variable('X');
    my $sy_val = variable('Y');
    $program->rule(
        head => call(succ => $sx_val, $sy_val),
        body => is_goal($sy_val, [$sx_val], sub ($v) {return $v + 1})
    );

    # 8. min(X, Y, Min) & max(X, Y, Max)
    my $mx1 = variable('X');
    my $my1 = variable('Y');

    $program->rule(
        head => call(min => $mx1, $my1, $mx1),
        body => guard([$mx1, $my1], sub ($a, $b) {return $a <= $b})
    );
    $program->rule(
        head => call(min => $mx1, $my1, $my1),
        body => guard([$mx1, $my1], sub ($a, $b) {return $a > $b})
    );

    $program->rule(
        head => call(max => $mx1, $my1, $mx1),
        body => guard([$mx1, $my1], sub ($a, $b) {return $a >= $b})
    );
    $program->rule(
        head => call(max => $mx1, $my1, $my1),
        body => guard([$mx1, $my1], sub ($a, $b) {return $a < $b})
    );

    # 9. between(Low, High, Val) generator
    $program->generator(
        between => 3,
        sub ($low, $high, $val) {
            return sub {return ()}
                unless defined $low && defined $high;
            my $curr = $low;
            return sub {
                return () if $curr > $high;
                my $res = $curr++;
                return [$low, $high, $res];
            };
        }
    );

    # Register metadata for standard library predicates
    my %stdlib_meta = (
        'append/3' => {
            doc     => 'Concatenates two lists (L1, L2) to produce Res',
            args    => ['L1', 'L2', 'Res'],
            builtin => 1,
        },
        'member/2' => {
            doc     => 'True if X is an element of List',
            args    => ['X', 'List'],
            builtin => 1,
        },
        'not_member/2' => {
            doc     => 'True if X is not an element of List',
            args    => ['X', 'List'],
            builtin => 1,
        },
        'length/2' => {
            doc     => 'True if Len is the integer length of List',
            args    => ['List', 'Len'],
            builtin => 1,
        },
        'list_length/2' => {
            doc     => 'Alias for length/2',
            args    => ['List', 'Len'],
            builtin => 1,
        },
        'reverse/2' => {
            doc     => 'True if Rev is the reversal of List',
            args    => ['List', 'Rev'],
            builtin => 1,
        },
        'reverse_list/2' => {
            doc     => 'Alias for reverse/2',
            args    => ['List', 'Rev'],
            builtin => 1,
        },
        'reverse_acc/3' => {
            doc     => 'Helper accumulator predicate for reverse/2',
            args    => ['List', 'Acc', 'Rev'],
            builtin => 1,
        },
        'select/3' => {
            doc     => 'True when removing X from List yields Rest',
            args    => ['X', 'List', 'Rest'],
            builtin => 1,
        },
        'permutation/2' => {
            doc     => 'True if Perm is a permutation of List',
            args    => ['List', 'Perm'],
            builtin => 1,
        },
        'succ/2' => {
            doc             => 'Successor relation: Y is X + 1',
            args            => ['X', 'Y'],
            builtin         => 1,
            ground_required => [0],
        },
        'min/3' => {
            doc             => 'True if Min is the minimum of numbers X and Y',
            args            => ['X', 'Y', 'Min'],
            builtin         => 1,
            ground_required => [0, 1],
        },
        'max/3' => {
            doc             => 'True if Max is the maximum of numbers X and Y',
            args            => ['X', 'Y', 'Max'],
            builtin         => 1,
            ground_required => [0, 1],
        },
        'between/3' => {
            doc             => 'Generates integers Val between Low and High inclusive',
            args            => ['Low', 'High', 'Val'],
            builtin         => 1,
            ground_required => [0, 1],
        },
    );

    for my $key (keys %stdlib_meta) {
        $program->set_predicate_metadata($key, $stdlib_meta{$key});
    }

    return;
}

1;
