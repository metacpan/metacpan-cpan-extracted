use Test2::V0;

use Devel::Optic;
use Devel::Size qw(total_size);

subtest 'initialization' => sub {
    for my $bogus_uplevel ('blorg', 0, -3) {
        like(
            dies { Devel::Optic->new(uplevel => $bogus_uplevel) },
            qr|uplevel should be integer >= 1, not '$bogus_uplevel'|,
            "bogus uplevel ($bogus_uplevel)"
        );
    }
};

subtest 'avoid summarizing empty structures by default' => sub {
    my $o = Devel::Optic->new();
    my $undef = undef;
    is($o->fit_to_view($undef), $undef, 'undef');
    my $string = "";
    is($o->fit_to_view($string), $string, 'empty string');
    my $num = 0;
    is($o->fit_to_view($num), $num, 'empty number');
    my $empty_arrayref = [];
    is($o->fit_to_view($empty_arrayref), $empty_arrayref, 'empty arrayref');
    my $empty_hashref = {};
    is($o->fit_to_view($empty_hashref), $empty_hashref, 'empty hashref');
};

subtest 'avoid summarizing small structures by default' => sub {
    my $o = Devel::Optic->new();
    my $string = "blorg";
    is($o->fit_to_view($string), $string, 'simple small string');
    my $num = 12234567;
    is($o->fit_to_view($num), $num, 'simple small number');
    my $arrayref = [qw(a b c d e f g)];
    is($o->fit_to_view($arrayref), $arrayref, 'small arrayref');
    my $hashref = {a => 1, b => 2, c => 3};
    is($o->fit_to_view($hashref), $hashref, 'small hashref');
};

subtest 'summarize subjectively big structures by default' => sub {
    my $o = Devel::Optic->new();
    my $string = "a" x Devel::Optic::DEFAULT_MAX_SIZE_BYTES;
    my $scalar_limit = Devel::Optic::DEFAULT_SCALAR_TRUNCATION_SIZE;
    like(
        $o->fit_to_view($string),
        qr|a* \(truncated to len $scalar_limit; len \d+ / \d+ bytes in full\)$|,
        'long string gets truncated message'
    );

    my $ref_limit = Devel::Optic::DEFAULT_MAX_SIZE_BYTES;
    my $arrayref_with_simple_scalar_members = [('a') x 100];
    my $arrayref_simple_len = scalar @$arrayref_with_simple_scalar_members;
    like(
        $o->fit_to_view($arrayref_with_simple_scalar_members),
        qr|ARRAY: \[a, a, a, a \.\.\.\] \(len $arrayref_simple_len / \d+ bytes\)$|,
        'big arrayref with simple string scalar members gets summarized',
        { total_size => total_size($arrayref_with_simple_scalar_members), len => $arrayref_simple_len, limit => $ref_limit }
    );

    my $arrayref_with_ref_members = [(['a'], { a => 1 }) x 100];
    my $arrayref_ref_len = scalar @$arrayref_with_ref_members;
    like(
        $o->fit_to_view($arrayref_with_ref_members),
        qr|ARRAY: \[ARRAY, HASH, ARRAY, HASH \.\.\.\] \(len $arrayref_ref_len / \d+ bytes\)$|,
        'big arrayref with mixed ref members gets summarized',
        { total_size => total_size($arrayref_with_ref_members), len => $arrayref_ref_len, limit => $ref_limit }
    );

    my $hashref_with_simple_scalar_values = { map { $_ => 'a' } (1 .. 100) };
    my $hashref_simple_values_keys = scalar keys %$hashref_with_simple_scalar_values;
    like(
        $o->fit_to_view($hashref_with_simple_scalar_values),
        qr|HASH: \{\d+ => a, \d+ => a, \d+ => a, \d+ => a \.\.\.\} \($hashref_simple_values_keys keys / \d+ bytes\)$|,
        'big hashref with simple string scalar values gets summarized',
        { total_size => total_size($hashref_with_simple_scalar_values), key_count => $hashref_simple_values_keys, limit => $ref_limit }
    );

    my $hashref_with_ref_values = { map { $_ => ['a'] } (1 .. 100) };
    my $hashref_ref_values_keys = scalar keys %$hashref_with_ref_values;
    like(
        $o->fit_to_view($hashref_with_ref_values),
        qr|HASH: \{\d+ => ARRAY, \d+ => ARRAY, \d+ => ARRAY, \d+ => ARRAY \.\.\.\} \($hashref_ref_values_keys keys / \d+ bytes\)$|,
        'big hashref with ref values gets summarized',
        { total_size => total_size($hashref_with_ref_values), key_count => $hashref_ref_values_keys, limit => $ref_limit }
    );
};

subtest 'check configurable limits' => sub {
    my $o = Devel::Optic->new(
        max_size => 1, # always summarize
        scalar_truncation_size => 1,
        scalar_sample_size => 1,
        sample_count => 1,
    );

    like(
        $o->fit_to_view("abc"),
        qr|a\.\.\. \(truncated to len 1; len \d+ / \d+ bytes in full\)$|,
        'string gets truncated message'
    );

    like(
        $o->fit_to_view(['a']),
        qr|ARRAY: \[a\] \(len 1 / \d+ bytes\)$|,
        'arrayref with simple string scalar members gets summarized'
    );

    like(
        $o->fit_to_view(['abc']),
        qr|ARRAY: \[a\.\.\.\] \(len 1 / \d+ bytes\)$|,
        'arrayref summary truncates long string scalar members'
    );

    like(
        $o->fit_to_view([qw(a b c d)]),
        qr|ARRAY: \[a \.\.\.\] \(len 4 / \d+ bytes\)$|,
        'arrayref summary shows sample_count members'
    );

    like(
        $o->fit_to_view({a => 'b'}),
        qr|HASH: \{a => b\} \(1 keys / \d+ bytes\)$|,
        'hashref with simple string scalar values gets summarized'
    );

    like(
        $o->fit_to_view({a => 'bcdefg'}),
        qr|HASH: \{a => b\.\.\.\} \(1 keys / \d+ bytes\)$|,
        'hashref summary truncates long string scalar value'
    );

    like(
        $o->fit_to_view({abcd => 'bcdefg'}),
        qr|HASH: \{a\.\.\. => b\.\.\.\} \(1 keys / \d+ bytes\)$|,
        'hashref summary truncates long key and long value'
    );

    like(
        $o->fit_to_view({a => 1, b => 2, c => 3}),
        qr|HASH: \{\w => \d \.\.\.\} \(3 keys / \d+ bytes\)$|,
        'hashref summary shows sample_count pairs'
    );
};

subtest 'sample count respects data structure size' => sub {
    my $o = Devel::Optic->new(
        max_size => 1, # always summarize
        scalar_truncation_size => 1,
        scalar_sample_size => 1,
        sample_count => 10,
    );

    like(
        $o->fit_to_view(['a']),
        qr|ARRAY: \[a\] \(len 1 / \d+ bytes\)$|,
        'arrayref with just one member shows only one sample'
    );

    like(
        $o->fit_to_view({a => 'b'}),
        qr|HASH: \{a => b\} \(1 keys / \d+ bytes\)$|,
        'hashref with one key shows only one sample'
    );
};

subtest 'weird ref types' => sub {
    my $o = Devel::Optic->new(
        max_size => 1, # always summarize
    );

    like(
        $o->fit_to_view(\'a'),
        qr|SCALAR a \(len \d+ / \d+ bytes\)|,
        'scalarref summary'
    );

    like(
        $o->fit_to_view(qr/foo/),
        qr|Regexp .+ \(len \d+ / \d+ bytes\)|,
        'regexp summary'
    );

    like(
        $o->fit_to_view(\*STDERR),
        qr|GLOB: \d+ bytes$|,
        'globref no summary'
    );

    like(
        $o->fit_to_view(\&Devel::Optic::new),
        qr|CODE: sub new \{ \.\.\. \} \(L\d+-\d+ in Devel::Optic \(.+\)\)$|,
        'coderef summary'
    );
};

done_testing;
