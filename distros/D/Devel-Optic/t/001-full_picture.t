use Test2::V0;

use Devel::Optic;

subtest 'empty data structures' => sub {
    my $o = Devel::Optic->new;
    my $undef = undef;
    is($o->full_picture('$undef'), $undef, 'undef');
    my $string = "blorb";
    is($o->full_picture('$string'), $string, 'simple string');
    my $num = 1234;
    is($o->full_picture('$num'), $num, 'simple number');
    my @empty_array = ();
    is($o->full_picture('@empty_array'), \@empty_array, 'empty array');
    my %empty_hash = ();
    is($o->full_picture('%empty_hash'), \%empty_hash, 'empty hash');
    my $empty_arrayref = [];
    is($o->full_picture('$empty_arrayref'), $empty_arrayref, 'empty arrayref');
    my $empty_hashref = {};
    is($o->full_picture('$empty_hashref'), $empty_hashref, 'empty hashref');
};

subtest 'valid index picking' => sub {
   my $o = Devel::Optic->new;
   my @array = qw(a b c d e f g);
   is($o->full_picture('@array/0'), $array[0], 'multi member array index 0');
   is($o->full_picture('@array/1'), $array[1], 'multi member array index 1');
   is($o->full_picture('@array/-1'), $array[-1], 'multi member negative array index -1');
   is($o->full_picture('@array/-2'), $array[-2], 'multi member negative array index -2');

   my $arrayref = [qw(a b c d e f g)];
   is($o->full_picture('$arrayref/0'), $arrayref->[0], 'multi member arrayref index 0');
   is($o->full_picture('$arrayref/1'), $arrayref->[1], 'multi member arrayref index 1');
   is($o->full_picture('$arrayref/-1'), $arrayref->[-1], 'multi member negative arrayref index -1');
   is($o->full_picture('$arrayref/-2'), $arrayref->[-2], 'multi member negative arrayref index -2');
};

subtest 'valid key picking' => sub {
   my $o = Devel::Optic->new;
   my %hash = (a => 1, b => 2, c => 3);
   is($o->full_picture('%hash/a'), $hash{a}, 'multi member hash key a');
   is($o->full_picture('%hash/b'), $hash{b}, 'multi member hash key b');
   is($o->full_picture('%hash/c'), $hash{c}, 'multi member hash key c');

   my $hashref = {a => 1, b => 2, c => 3};
   is($o->full_picture('$hashref/a'), $hashref->{a}, 'multi member hashref key a');
   is($o->full_picture('$hashref/b'), $hashref->{b}, 'multi member hashref key b');
   is($o->full_picture('$hashref/c'), $hashref->{c}, 'multi member hashref key c');
};

subtest 'valid deep routes, single data type' => sub {
    my $o = Devel::Optic->new;
    my @array = ([[[42]]]);
    is($o->full_picture('@array/0/0/0/0'), $array[0]->[0]->[0]->[0], 'array nested index');

    my %hash = (foo => { foo => { foo => { foo => 42}}});
    is($o->full_picture('%hash/foo/foo/foo/foo'), $hash{foo}->{foo}->{foo}->{foo}, 'hash nested key');
    my $arrayref = [[[[42]]]];
    is($o->full_picture('$arrayref/0/0/0/0'), $arrayref->[0]->[0]->[0]->[0], 'arrayref nested index');
    my $hashref = {foo => { foo => { foo => { foo => 42}}}};
    is($o->full_picture('$hashref/foo/foo/foo/foo'), $hashref->{foo}->{foo}->{foo}->{foo}, 'hashref nested key');
};

subtest 'valid deep routes, mixed data types' => sub {
    my $o = Devel::Optic->new;
    my @array = ({ foo => [{ foo => 42}]});
    is($o->full_picture('@array/0/foo/0/foo'), $array[0]->{foo}->[0]->{foo}, 'array nested mixed type index');

    my %hash = (foo => [{ foo => [42]}]);
    is($o->full_picture('%hash/foo/0/foo/0'), $hash{foo}->[0]->{foo}->[0], 'hash nested mixed type key');

    my $arrayref = [{ foo => [{ foo => 42}]}];
    is($o->full_picture('$arrayref/0/foo/0/foo'), $arrayref->[0]->{foo}->[0]->{foo}, 'arrayref nested mixed type index');

    my $hashref = {foo => [{ foo => [42]}]};
    is($o->full_picture('$hashref/foo/0/foo/0'), $hash{foo}->[0]->{foo}->[0], 'hashref nested mixed type key');
};

subtest 'invalid routes' => sub {
    # 'uplevel 3' because 'dies' creates a new scope
    my $o = Devel::Optic->new(uplevel => 3);

    like(
        dies { $o->full_picture('') },
        qr/\$route must not be empty/,
        "exception for variable that does not exist"
    );

    like(
        dies { $o->full_picture('//') },
        qr/\$route must not be empty/,
        "exception for variable that does not exist"
    );

    like(
        dies { $o->full_picture('#weird/foo/bar') },
        qr/\$route must start with a Perl variable name \(like "\$scalar", "\@array", or "\%hash"\)/,
        "exception for variable that does not exist"
    );

    like(
        dies { $o->full_picture('$totally_bogus_scalar') },
        qr/variable '\$totally_bogus_scalar' is not a lexical variable in scope/,
        "exception for variable that does not exist"
    );

    like(
        dies { $o->full_picture('@totally_bogus_array') },
        qr/variable '\@totally_bogus_array' is not a lexical variable in scope/,
        "exception for variable that does not exist"
    );

    like(
        dies { $o->full_picture('%totally_bogus_hash') },
        qr/variable '\%totally_bogus_hash' is not a lexical variable in scope/,
        "exception for variable that does not exist"
    );

    my $undef = undef;
    like(
        dies { $o->full_picture('$undef/foo') },
        qr|'\$undef' points to ref of type 'NOT-A-REF'\. '\$undef/foo' points deeper, but Devel::Optic doesn't know how to traverse further|,
        "exception for indexing into undef"
    );

    my @array = (42);
    like(
        dies { $o->full_picture('@array/1') },
        qr|'\@array/1' does not exist: array '\@array' is only 1 elements long|,
        "exception for indexing into undef"
    );

    like(
        dies { $o->full_picture('@array/-2') },
        qr|'\@array/-2' does not exist: array '\@array' is only 1 elements long|,
        "exception for indexing into undef"
    );

    my $arrayref = [42];
    like(
        dies { $o->full_picture('$arrayref/1') },
        qr|'\$arrayref/1' does not exist: array '\$arrayref' is only 1 elements long|,
        "exception for indexing into undef"
    );

    like(
        dies { $o->full_picture('$arrayref/-2') },
        qr|'\$arrayref/-2' does not exist: array '\$arrayref' is only 1 elements long|,
        "exception for indexing into undef"
    );

    my %hash = (a => 1, b => 2, c => 3);
    like(
        dies { $o->full_picture('%hash/foo') },
        qr|'\%hash/foo' does not exist: no key 'foo' in hash '\%hash'|,
        "exception for indexing into undef"
    );
};

done_testing;
