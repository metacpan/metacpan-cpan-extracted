#!perl

use 5.010;
use strict;
use warnings;

use Getopt::Long::Less qw(Configure GetOptions GetOptionsFromArray);
use Test::Exception;
use Test::More 0.98;

subtest "basics" => sub {
    test_getopt(
        name => 'case sensitive',
        args => [{}, "foo"],
        argv => ["--Foo"],
        success => 0,
    );
    test_getopt(
        name => 'empty argv',
        args => [{}, "foo=s"],
        argv => [],
        success => 1,
        expected_res_hash => {},
        remaining => [],
    );
    test_getopt(
        name => '-- (1)',
        args => [{}, "foo=s"],
        argv => ["--"],
        success => 1,
        expected_res_hash => {},
        remaining => [],
    );
    test_getopt(
        name => '-- (2)',
        args => [{}, "foo=s"],
        argv => ["--", "--foo"],
        success => 1,
        expected_res_hash => {},
        remaining => ["--foo"],
    );

    test_getopt(
        name => 'unknown argument -> error (1)',
        args => [{}, "bar=s", "foo=s"],
        argv => ["--bar", "--val", "--qux"],
        success => 0,
        expected_res_hash => {bar=>"--val"},
        remaining => ["--qux"],
    );
    test_getopt(
        name => 'unknown argument -> error (2)',
        args => [{}, "bar=s", "foo=s"],
        argv => ["--qux", "--bar", "--val"],
        success => 0,
        expected_res_hash => {bar=>"--val"},
        remaining => ["--qux"],
    );
    test_getopt(
        name => 'prefix matching',
        args => [{}, "bar=s"],
        argv => ["--ba", "--val"],
        success => 1,
        expected_res_hash => {bar=>"--val"},
        remaining => [],
    );
    test_getopt(
        name => 'ambiguous prefix -> error',
        args => [{}, "bar=s", "baz=s"],
        argv => ["--ba", "--val"],
        success => 0,
        expected_res_hash => {},
        remaining => ['--val'],
    );
    test_getopt(
        name => 'missing required argument -> error',
        args => [{}, "bar=s"],
        argv => ["--bar"],
        success => 0,
        expected_res_hash => {},
        remaining => [],
    );

    test_getopt(
        name => 'optional argument 1',
        args => [{}, "bar:s"],
        argv => ["--bar"],
        success => 1,
        expected_res_hash => {bar=>''},
        remaining => [],
    );
    test_getopt(
        name => 'optional argument 1',
        args => [{}, "bar:i", "foo"],
        argv => ["--bar", "--foo"],
        success => 1,
        expected_res_hash => {bar=>0, foo=>1},
        remaining => [],
    );
    test_getopt(
        name => 'optional argument 1',
        args => [{}, "bar:i", "foo"],
        argv => ["--bar", 3, "--foo"],
        success => 1,
        expected_res_hash => {bar=>3, foo=>1},
        remaining => [],
    );
};

subtest "gnu compat" => sub {
    test_getopt(
        name => '(1)',
        args => [{}, "foo=s"],
        argv => ["--foo=x", "y"],
        success => 1,
        expected_res_hash => {foo=>"x"},
        remaining => ["y"],
    );
    test_getopt(
        name => '(2)',
        args => [{}, "foo=s"],
        argv => ["--foo=", "y"],
        success => 1,
        expected_res_hash => {foo=>""},
        remaining => ["y"],
    );
};

subtest "destination" => sub {
    my $h = {};
    test_getopt(
        name => 'nonref (noop)',
        args => ["foo=s"=>1],
        argv => ["--foo", "val"],
        success => 1,
    );
    test_getopt(
        name => 'scalarref',
        args => ["foo=s"=>\$h->{foo}],
        argv => ["--foo", "val"],
        success => 1,
        input_res_hash => $h,
        expected_res_hash => {foo=>"val"},
        remaining => [],
    );
    test_getopt(
        name => 'hashref (in first argument)',
        args => [{}, "foo=s", "bar", "baz=i"],
        argv => ["--foo", "val", "--bar", "--baz", 3],
        success => 1,
        expected_res_hash => {foo=>"val", bar=>1, baz=>3},
        remaining => [],
    );
    test_getopt(
        name => 'coderef',
        args => ["foo=s" => sub { $h->{foo} = $_[1] }],
        argv => ["--foo", "--val"],
        success => 1,
        input_res_hash => $h,
        expected_res_hash => {foo=>"--val"},
        remaining => [],
    );
    # XXX arrayref
};

subtest "type" => sub {
    test_getopt(
        name => 'type checking for type=i (success)',
        args => [{}, "foo=i"],
        argv => ["--foo", "-2"],
        success => 1,
        expected_res_hash => {foo=>"-2"},
        remaining => [],
    );
    test_getopt(
        name => 'type checking for type=i (fail 1)',
        args => [{}, "foo=i"],
        argv => ["--foo", "a"],
        success => 0,
    );
    test_getopt(
        name => 'type checking for type=i (fail 2)',
        args => [{}, "foo=i"],
        argv => ["--foo", "1.2"],
        success => 0,
    );
    # unlike Getopt::Long, i decidedly don't want to allow 1_000 like in perl
    # for now
    test_getopt(
        name => 'type checking for type=i (fail 3)',
        args => [{}, "foo=i"],
        argv => ["--foo", "1_000"],
        success => 0,
    );

    test_getopt(
        name => 'type checking for type=f (success)',
        args => [{}, "f1=f", "f2=f", "f3=f", "f4=f", "f5=f", "f6=f"],
        argv => [qw/--f1 1 --f2 -23 --f3 0.1 --f4 1e-4 --f5 .1 --f6 .1e1/],
        success => 1,
        expected_res_hash => {f1=>'1',f2=>'-23',f3=>'0.1',f4=>'1e-4',f5=>'.1',f6=>'.1e1'},
        remaining => [],
    );
    test_getopt(
        name => 'type checking for type=f (fail 1)',
        args => [{}, "foo=f"],
        argv => ["--foo", "e"],
        success => 0,
    );
    test_getopt(
        name => 'type checking for type=f (fail 2)',
        args => [{}, "foo=f"],
        argv => ["--foo", "1e"],
        success => 0,
    );
    test_getopt(
        name => 'type checking for type=f (fail 3)',
        args => [{}, "foo=f"],
        argv => ["--foo", "."],
        success => 0,
    );
    # unlike Getopt::Long, i decidedly don't want to allow 1_000 like in perl
    # for now
    test_getopt(
        name => 'type checking for type=f (fail 4)',
        args => [{}, "foo=f"],
        argv => ["--foo", "1_000.1"],
        success => 0,
    );

    test_getopt(
        name => 'default value for type=i',
        args => [{}, "foo:i"],
        argv => ["--foo"],
        success => 1,
        expected_res_hash => {foo=>0},
        remaining => [],
    );
    test_getopt(
        name => 'default value for type=f',
        args => [{}, "foo:f"],
        argv => ["--foo"],
        success => 1,
        expected_res_hash => {foo=>0},
        remaining => [],
    );
    test_getopt(
        name => 'default value for type=s',
        args => [{}, "foo:s"],
        argv => ["--foo"],
        success => 1,
        expected_res_hash => {foo=>''},
        remaining => [],
    );
    test_getopt(
        name => 'default value for negatable option (positive)',
        args => [{}, "foo!"],
        argv => ["--foo"],
        success => 1,
        expected_res_hash => {foo=>1},
        remaining => [],
    );
    test_getopt(
        name => 'default value for negatable option (negative 1)',
        args => [{}, "foo!"],
        argv => ["--nofoo"],
        success => 1,
        expected_res_hash => {foo=>0},
        remaining => [],
    );
    test_getopt(
        name => 'default value for negatable option (negative 2)',
        args => [{}, "foo!"],
        argv => ["--no-foo"],
        success => 1,
        expected_res_hash => {foo=>0},
        remaining => [],
    );

    my $h = {};
    test_getopt(
        name => 'default value for increment option (1)',
        args => [$h, "foo+"],
        argv => ["--foo"],
        success => 1,
        expected_res_hash => {foo=>1},
        remaining => [],
    );
    test_getopt(
        name => 'default value for increment option (2)',
        args => ["foo+" => \$h->{foo}],
        argv => ["--foo", "--foo", "--foo"],
        success => 1,
        input_res_hash => $h,
        expected_res_hash => {foo=>4},
        remaining => [],
    );
};

subtest "bundling" => sub {
    test_getopt(
        name => '(1)',
        args => [{}, "foo|f=s", "bar|b"],
        argv => ["-fb"],
        success => 1,
        expected_res_hash => {foo=>"b"},
        remaining => [],
    );
    test_getopt(
        name => '(2)',
        args => [{}, "foo|f=s", "bar|b"],
        argv => ["-bfb"],
        success => 1,
        expected_res_hash => {bar=>1, foo=>"b"},
        remaining => [],
    );
    test_getopt(
        name => 'option argument from next argument',
        args => [{}, "foo|f=s", "bar|b"],
        argv => ["-bf", "b"],
        success => 1,
        expected_res_hash => {bar=>1, foo=>"b"},
        remaining => [],
    );
    test_getopt(
        name => 'missing required argument -> error',
        args => [{}, "foo|f=s", "bar|b"],
        argv => ["-bf"],
        success => 0,
        expected_res_hash => {bar=>1},
        remaining => [],
    );
};

sub test_getopt {
    my %args = @_;

    my $name = $args{name} // do {
        my $name = '';
        if (ref($args{args}[0]) eq 'HASH') {
            $name .= "spec:[".join(", ", @{ $args{args} }[1..@{$args{args}}-1])."]";
        } else {
            my %spec = @{ $args{args} };
            $name .= "spec:[".join(", ", sort keys %spec)."]";
        }
        $name .= " argv:[".join("", @{$args{argv}})."]";
        $name;
    };

    subtest $name => sub {
        my $old_opts;
        $old_opts = Configure(@{ $args{configure} }) if $args{configure};

        my @argv = @{ $args{argv} };
        my $res;
        eval { $res = GetOptionsFromArray(\@argv, @{ $args{args} }) };

        if ($args{dies}) {
            ok($@, "dies") or goto RETURN;
        } else {
            ok(!$@, "doesn't die") or do {
                diag explain "err=$@";
                goto RETURN;
            };
        }

        if (defined($args{success})) {
            is(!!$res, !!$args{success}, "success=$args{success}");
        }

        if ($args{expected_res_hash}) {
            # in 'input_res_hash', user supplies the hash she uses to store the
            # options in (optional if first argument is hashref).
            my $res_hash = $args{input_res_hash} //
                (ref($args{args}[0]) eq 'HASH' ? $args{args}[0] : undef);
            die "BUG: Please specify input_res_hash" unless $res_hash;

            is_deeply($res_hash, $args{expected_res_hash}, "res_hash")
                or diag explain $res_hash;
        }

        if ($args{remaining}) {
            is_deeply(\@argv, $args{remaining}, "remaining")
                or diag explain \@argv;
        }

      RETURN:
        Configure($old_opts) if $old_opts;
    };
}

done_testing;
