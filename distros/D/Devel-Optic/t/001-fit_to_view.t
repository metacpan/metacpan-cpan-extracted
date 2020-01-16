use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;

use Devel::Optic;

subtest 'initialization' => sub {
    for my $bogus_uplevel ('blorg', 0, -3) {
        like(
            dies { Devel::Optic->new(uplevel => $bogus_uplevel) },
            qr|uplevel should be integer >= 1, not '$bogus_uplevel'|,
            "bogus uplevel ($bogus_uplevel)"
        );
    }
};

subtest 'summarize empty structures' => sub {
    my $o = Devel::Optic->new();
    my $undef = undef;
    is($o->fit_to_view($undef), "(undef)", 'undef');
    my $string = "";
    is($o->fit_to_view($string), '"" (len 0)', 'empty string');
    my $num = 0;
    is($o->fit_to_view($num), "$num (len 1)", 'empty number');
    my $empty_arrayref = [];
    is($o->fit_to_view($empty_arrayref), "ARRAY: [] (len 0)", 'empty arrayref');
    my $empty_hashref = {};
    is($o->fit_to_view($empty_hashref), "HASH: {} (0 keys)", 'empty hashref');
};

subtest 'summarize small structures' => sub {
    my $o = Devel::Optic->new();
    my $string = "blorg";
    is($o->fit_to_view($string), "$string (len 5)", 'simple small string');
    my $num = 1223;
    is($o->fit_to_view($num), "$num (len 4)", 'simple small number');
    my $arrayref = [qw(a b c d)];
    is($o->fit_to_view($arrayref), "ARRAY: [a, b, c, d] (len 4)", 'small arrayref');
    my $hashref = {a => 1, b => 2, c => 3};
    like($o->fit_to_view($hashref), qr|HASH: \{\w => \d, \w => \d, \w => \d\} \(3 keys\)|, 'small hashref');
};

subtest 'summarize subjectively big structures' => sub {
    my $o = Devel::Optic->new();
    my $string = "a" x 500;
    my $scalar_limit = Devel::Optic::DEFAULT_SCALAR_TRUNCATION_SIZE;
    like(
        $o->fit_to_view($string),
        qr|a* \(truncated to len $scalar_limit; len \d+\)$|,
        'long string gets truncated message'
    );

    my $arrayref_with_simple_scalar_members = [('a') x 100];
    my $arrayref_simple_len = scalar @$arrayref_with_simple_scalar_members;
    like(
        $o->fit_to_view($arrayref_with_simple_scalar_members),
        qr|ARRAY: \[a, a, a, a \.\.\.\] \(len $arrayref_simple_len\)$|,
        'big arrayref with simple string scalar members gets summarized',
        { len => $arrayref_simple_len }
    );

    my $arrayref_with_ref_members = [(['a'], { a => 1 }) x 100];
    my $arrayref_ref_len = scalar @$arrayref_with_ref_members;
    like(
        $o->fit_to_view($arrayref_with_ref_members),
        qr|ARRAY: \[ARRAY, HASH, ARRAY, HASH \.\.\.\] \(len $arrayref_ref_len\)$|,
        'big arrayref with mixed ref members gets summarized',
        { len => $arrayref_ref_len }
    );

    my $hashref_with_simple_scalar_values = { map { $_ => 'a' } (1 .. 100) };
    my $hashref_simple_values_keys = scalar keys %$hashref_with_simple_scalar_values;
    like(
        $o->fit_to_view($hashref_with_simple_scalar_values),
        qr|HASH: \{\d+ => a, \d+ => a, \d+ => a, \d+ => a \.\.\.\} \($hashref_simple_values_keys keys\)$|,
        'big hashref with simple string scalar values gets summarized',
        { key_count => $hashref_simple_values_keys }
    );

    my $hashref_with_ref_values = { map { $_ => ['a'] } (1 .. 100) };
    my $hashref_ref_values_keys = scalar keys %$hashref_with_ref_values;
    like(
        $o->fit_to_view($hashref_with_ref_values),
        qr|HASH: \{\d+ => ARRAY, \d+ => ARRAY, \d+ => ARRAY, \d+ => ARRAY \.\.\.\} \($hashref_ref_values_keys keys\)$|,
        'big hashref with ref values gets summarized',
        { key_count => $hashref_ref_values_keys }
    );
};

subtest 'check configurable limits' => sub {
    my $o = Devel::Optic->new(
        scalar_truncation_size => 1,
        scalar_sample_size => 1,
        sample_count => 1,
    );

    like(
        $o->fit_to_view("abc"),
        qr|a\.\.\. \(truncated to len 1; len \d+\)$|,
        'string gets truncated message'
    );

    like(
        $o->fit_to_view(['a']),
        qr|ARRAY: \[a\] \(len 1\)$|,
        'arrayref with simple string scalar members gets summarized'
    );

    like(
        $o->fit_to_view(['abc']),
        qr|ARRAY: \[a\.\.\.\] \(len 1\)$|,
        'arrayref summary truncates long string scalar members'
    );

    like(
        $o->fit_to_view([qw(a b c d)]),
        qr|ARRAY: \[a \.\.\.\] \(len 4\)$|,
        'arrayref summary shows sample_count members'
    );

    like(
        $o->fit_to_view({a => 'b'}),
        qr|HASH: \{a => b\} \(1 keys\)$|,
        'hashref with simple string scalar values gets summarized'
    );

    like(
        $o->fit_to_view({a => 'bcdefg'}),
        qr|HASH: \{a => b\.\.\.\} \(1 keys\)$|,
        'hashref summary truncates long string scalar value'
    );

    like(
        $o->fit_to_view({abcd => 'bcdefg'}),
        qr|HASH: \{a\.\.\. => b\.\.\.\} \(1 keys\)$|,
        'hashref summary truncates long key and long value'
    );

    like(
        $o->fit_to_view({a => 1, b => 2, c => 3}),
        qr|HASH: \{\w => \d \.\.\.\} \(3 keys\)$|,
        'hashref summary shows sample_count pairs'
    );
};

subtest 'sample count respects data structure size' => sub {
    my $o = Devel::Optic->new(
        scalar_truncation_size => 1,
        scalar_sample_size => 1,
        sample_count => 10,
    );

    like(
        $o->fit_to_view(['a']),
        qr|ARRAY: \[a\] \(len 1\)$|,
        'arrayref with just one member shows only one sample'
    );

    like(
        $o->fit_to_view({a => 'b'}),
        qr|HASH: \{a => b\} \(1 keys\)$|,
        'hashref with one key shows only one sample'
    );
};

subtest 'copes with undef keys' => sub {
    my $o = Devel::Optic->new();

    like(
        $o->fit_to_view([undef]),
        qr|ARRAY: \[\(undef\)\] \(len 1\)$|,
        'arrayref with undef member samples (undef)'
    );

    like(
        $o->fit_to_view({a => undef}),
        qr|HASH: \{a => \(undef\)\} \(1 keys\)$|,
        'hashref with undef value samples (undef)'
    );

    like(
        $o->fit_to_view([undef, 'a', undef, 'b']),
        qr|ARRAY: \[\(undef\), a, \(undef\), b\] \(len 4\)$|,
        'arrayref with mixed undef and real member samples (undef)'
    );

    # not doing a mixed hash because the random ordering is annoying to test. The
    # random shuffle is probably a reasonable way to get coverage over a range
    # of possible hash keys, though, so until there's some other way to see
    # them I'd rather not sort the summary output.
};


subtest 'weird ref types' => sub {
    my $o = Devel::Optic->new();

    like(
        $o->fit_to_view(\'a'),
        qr|SCALAR a \(len \d+\)|,
        'scalarref summary'
    );

    like(
        $o->fit_to_view(qr/foo/),
        qr|Regexp .+ \(len \d+\)|,
        'regexp summary'
    );

    like(
        $o->fit_to_view(\*STDERR),
        qr|GLOB: \(no sample\)|,
        'globref no summary'
    );

    like(
        $o->fit_to_view(\&Devel::Optic::new),
        qr|CODE: sub new \{ \.\.\. \} \(L\d+-\d+ in Devel::Optic \(.+\)\)$|,
        'coderef summary'
    );
};

done_testing;
