use Test2::V0;

use Devel::Optic::Lens::Perlish;

subtest 'empty/simple data structures' => sub {
    my $p = Devel::Optic::Lens::Perlish->new;

    my $undef = undef;
    is($p->inspect({'$undef' => $undef}, '$undef'), $undef, 'undef');

    my $string = "blorb";
    is($p->inspect({'$string' => $string}, '$string'), $string, 'simple string');

    my $num = 1234;
    is($p->inspect({'$num' => $num}, '$num'), $num, 'simple number');

    my @empty_array = ();
    is($p->inspect({'@empty_array' => \@empty_array}, '@empty_array'), \@empty_array, 'empty array');

    my @simple_array = (1, 2, 3);
    is($p->inspect({'@simple_array' => \@simple_array}, '@simple_array'), \@simple_array, 'simple array');

    my %empty_hash = ();
    is($p->inspect({'%empty_hash' => \%empty_hash}, '%empty_hash'), \%empty_hash, 'empty hash');

    my %simple_hash = (a => 1, b => 2, c => 3);
    is($p->inspect({'%simple_hash' => \%simple_hash}, '%simple_hash'), \%simple_hash, 'simple hash');

    my $empty_arrayref = [];
    is($p->inspect({'$empty_arrayref' => \$empty_arrayref}, '$empty_arrayref'), $empty_arrayref, 'empty arrayref');

    my $simple_arrayref = [1, 2, 3];
    is($p->inspect({'$simple_arrayref' => \$simple_arrayref}, '$simple_arrayref'), $simple_arrayref, 'simple arrayref');

    my $empty_hashref = {};
    is($p->inspect({'$empty_hashref' => \$empty_hashref}, '$empty_hashref'), $empty_hashref, 'empty hashref');

    my $simple_hashref = {a => 1, b => 2, c => 3};
    is($p->inspect({'$simple_hashref' => \$simple_hashref}, '$simple_hashref'), $simple_hashref, 'simple hashref');
};

subtest 'valid index picking' => sub {
    my $p = Devel::Optic::Lens::Perlish->new;
    my @array = qw(a b c d e f g);
    my $scope = {
        '@array' => \@array
    };

    is($p->inspect($scope, '@array->[0]'), $array[0], 'multi member array index 0');
    is($p->inspect($scope, '@array->[1]'), $array[1], 'multi member array index 1');
    is($p->inspect($scope, '@array->[-1]'), $array[-1], 'multi member negative array index -1');
    is($p->inspect($scope, '@array->[-2]'), $array[-2], 'multi member negative array index -2');

    my $arrayref = [qw(a b c d e f g)];
    $scope = {
        '$arrayref' => \$arrayref,
    };

    is($p->inspect($scope, '$arrayref->[0]'), $arrayref->[0], 'multi member arrayref index 0');
    is($p->inspect($scope, '$arrayref->[1]'), $arrayref->[1], 'multi member arrayref index 1');
    is($p->inspect($scope, '$arrayref->[-1]'), $arrayref->[-1], 'multi member negative arrayref index -1');
    is($p->inspect($scope, '$arrayref->[-2]'), $arrayref->[-2], 'multi member negative arrayref index -2');
};

subtest 'valid key picking' => sub {
    my $p = Devel::Optic::Lens::Perlish->new;
    my %hash = (a => 1, b => 2, c => 3);
    my $scope = {
        '%hash' => \%hash,
    };

    is($p->inspect($scope, q|%hash->{'a'}|), $hash{a}, 'multi member hash key a');
    is($p->inspect($scope, q|%hash->{'b'}|), $hash{b}, 'multi member hash key b');
    is($p->inspect($scope, q|%hash->{'c'}|), $hash{c}, 'multi member hash key c');

    my $hashref = {a => 1, b => 2, c => 3};
    $scope = {
        '$hashref' => \$hashref,
    };

    is($p->inspect($scope, q|$hashref->{'a'}|), $hashref->{a}, 'multi member hashref key a');
    is($p->inspect($scope, q|$hashref->{'b'}|), $hashref->{b}, 'multi member hashref key b');
    is($p->inspect($scope, q|$hashref->{'c'}|), $hashref->{c}, 'multi member hashref key c');
};

subtest 'valid deep queries, single data type' => sub {
    my $p = Devel::Optic::Lens::Perlish->new;
    my @array = ([[[42]]]);
    my $scope = { '@array' => \@array };
    is($p->inspect($scope, '@array->[0]->[0]->[0]->[0]'), $array[0]->[0]->[0]->[0], 'array nested index');

    my %hash = (foo => { foo => { foo => { foo => 42}}});
    $scope = { '%hash' => \%hash };
    is($p->inspect($scope, q|%hash->{'foo'}->{'foo'}->{'foo'}->{'foo'}|), $hash{foo}->{foo}->{foo}->{foo}, 'hash nested key');

    my $arrayref = [[[[42]]]];
    $scope = { '$arrayref' => \$arrayref };
    is($p->inspect($scope, '$arrayref->[0]->[0]->[0]->[0]'), $arrayref->[0]->[0]->[0]->[0], 'arrayref nested index');

    my $hashref = {foo => { foo => { foo => { foo => 42}}}};
    $scope = { '$hashref' => \$hashref };
    is($p->inspect($scope, q|$hashref->{'foo'}->{'foo'}->{'foo'}->{'foo'}|), $hashref->{foo}->{foo}->{foo}->{foo}, 'hashref nested key');
};

subtest 'valid deep queries, mixed data types' => sub {
    my $p = Devel::Optic::Lens::Perlish->new;
    my @array = ({ foo => [{ foo => 42}]});
    my $scope = { '@array' => \@array };
    is($p->inspect($scope, q|@array->[0]->{'foo'}->[0]->{'foo'}|), $array[0]->{foo}->[0]->{foo}, 'array nested mixed type index');

    my %hash = (foo => [{ foo => [42]}]);
    $scope = { '%hash' => \%hash };
    is($p->inspect($scope, q|%hash->{'foo'}->[0]->{'foo'}->[0]|), $hash{foo}->[0]->{foo}->[0], 'hash nested mixed type key');

    my $arrayref = [{ foo => [{ foo => 42}]}];
    $scope = { '$arrayref' => \$arrayref };
    is($p->inspect($scope, q|$arrayref->[0]->{'foo'}->[0]->{'foo'}|), $arrayref->[0]->{foo}->[0]->{foo}, 'arrayref nested mixed type index');

    my $hashref = {foo => [{ foo => [42]}]};
    $scope = { '$hashref' => \$hashref };
    is($p->inspect($scope, q|$hashref->{'foo'}->[0]->{'foo'}->[0]|), $hash{foo}->[0]->{foo}->[0], 'hashref nested mixed type key');
};

subtest 'nested queries' => sub {
    my $p = Devel::Optic::Lens::Perlish->new;
    my $key = "a";
    my $index = 0;
    my @array = ({ $key => [{ $key => 1}]});
    my $scope = { '@array' => \@array, '$key' => $key, '$index' => $index };
    is(
        $p->inspect($scope, q|@array->[$index]->{$key}->[$index]->{$key}|),
        $array[$index]->{$key}->[$index]->{$key},
        'nested resolution, array + simple symbol',
    );

    my %hash = ($key => [{ $key => [1]}]);
    $scope = { '%hash' => \%hash, '$key' => $key, '$index' => $index };
    is(
        $p->inspect($scope, q|%hash->{$key}->[$index]->{$key}->[$index]|),
        $hash{$key}->[$index]->{$key}->[$index],
        'nested resolution, hash + simple symbol',
    );

    $scope = { '$foo' => ['needle'], '$bar' => [0], '$baz' => [0], '$qux' => [0] };
    is(
        $p->inspect($scope, q|$foo->[$bar->[$baz->[$qux->[0]]]]|),
        'needle',
        'nested resolution, array + multi-tier array resolution',
    );

    $scope = { '$foo' => { a => 'needle' }, '$bar' => { a => 'a' }, '$baz' => { a => 'a' }, '$qux' => { a => 'a' } };
    is(
        $p->inspect($scope, q|$foo->{$bar->{$baz->{$qux->{'a'}}}}|),
        'needle',
        'nested resolution, hash + multi-tier hash resolution',
    );

    $scope = { '$foo' => { a => 'needle' }, '$bar' => ['a'], '$baz' => { a => 0 }, '$qux' => ['a'], '$index' => 0, };
    is(
        $p->inspect($scope, q|$foo->{$bar->[$baz->{$qux->[$index]}]}|),
        'needle',
        'nested resolution, hash + multi-tier mixed resolution',
    );
};

subtest 'invalid queries' => sub {
    my $p = Devel::Optic::Lens::Perlish->new;

    like(
        dies { $p->inspect({}, undef) },
        qr/invalid syntax: undefined query/,
        "undefined query exception"
    );

    like(
        dies { $p->inspect({}, '') },
        qr/invalid syntax: empty query/,
        "empty query exception"
    );

    like(
        dies { $p->inspect({}, q|#weird->{'foo'}->{'bar'}|) },
        qr/invalid syntax: query must start with a Perl symbol \(prefixed by a \$, \@, or \% sigil\)/,
        "query doesn't start with a sigil exception"
    );

    like(
        dies { $p->inspect({}, '$bogus_scalar') },
        qr/no symbol '\$bogus_scalar' in scope/,
        "symbol not in scope"
    );

    for my $symbol (qw(@bogus_array %bogus_hash)) {
        like(
            dies { $p->inspect({}, $symbol) },
            qr/no symbol '$symbol' in scope/,
            "symbol not in scope"
        );
    }

    like(
        dies { $p->inspect({ '$undef' => undef }, q|$undef->{'foo'}|) },
        qr|invalid hash access: '\$undef' is undef, not hash|,
        "exception for keying into undef"
    );

    like(
        dies { $p->inspect({ '$undef' => undef }, q|$undef->[0]|) },
        qr|invalid array access: '\$undef' is undefined, not array|,
        "exception for indexing into undef"
    );

    like(
        dies { $p->inspect({ '$arrayref' => [] }, q|$arrayref->{'foo'}|) },
        qr|invalid hash access: '\$arrayref' is ARRAYREF, not hash|,
        "access array as hash"
    );

    like(
        dies { $p->inspect({ '$hashref' => {} }, q|$hashref->[0]|) },
        qr|invalid array access: '\$hashref' is HASHREF, not array|,
        "access hash as array"
    );

    like(
        dies { $p->inspect({ '@array' => [42] }, q|@array->[3]|) },
        qr|out of bounds: index '3', but len\(\@array\) == 1|,
        "literal index out of bounds"
    );

    like(
        dies { $p->inspect({ '@array' => [42] }, '@array->[-2]') },
        qr|out of bounds: index '-2', but len\(\@array\) == 1|,
        "literal negative index out of bounds"
    );

    like(
        dies { $p->inspect({ '@array' => [42], '$index' => 1 }, q|@array->[$index]|) },
        qr|out of bounds: index \$index == '1', but len\(\@array\) == 1|,
        "symbolic index out of bounds"
    );

    like(
        dies { $p->inspect({ '@array' => [42], '$index' => -2 }, q|@array->[$index]|) },
        qr|out of bounds: index \$index == '-2', but len\(\@array\) == 1|,
        "symbolic negative index out of bounds"
    );

    like(
        dies { $p->inspect({ '@array' => [42], '$string_index' => 'foo' }, q|@array->[$string_index]|) },
        qr|invalid array index in '\@array->\[\$string_index\]': \$string_index == 'foo' \(not a number\)|,
        "symbolic string index"
    );

    like(
        dies { $p->inspect({ '@array' => [42], '$ref_index' => [] }, q|@array->[$ref_index]|) },
        qr|invalid array index in '\@array->\[\$ref_index\]': \$ref_index == 'ARRAYREF' \(not a number\)|,
        "symbolic ref index"
    );

    like(
        dies { $p->inspect({ '%hash' => {a => 1} }, q|%hash->{'foo'}|) },
        qr|invalid hash key: 'foo' is not in %hash|,
        "literal key does not exist"
    );

    like(
        dies { $p->inspect({ '%hash' => {a => 1}, '$key' => 'foo' }, q|%hash->{$key}|) },
        qr|invalid hash key: \$key == 'foo' is not in %hash|,
        "symbolic key does not exist"
    );

    like(
        dies { $p->inspect({ '%hash' => {a => 1}, '$key' => 'foo' }, q|%hash->{$key}|) },
        qr|invalid hash key: \$key == 'foo' is not in %hash|,
        "symbolic key does not exist"
    );

    like(
        dies { $p->inspect({ '%hash' => {a => 1}, '$ref_key' => [] }, q|%hash->{$ref_key}|) },
        qr|invalid hash key in '\%hash->\{\$ref_key\}': \$ref_key == 'ARRAYREF'|,
        "symbolic ref key"
    );
};

done_testing;
