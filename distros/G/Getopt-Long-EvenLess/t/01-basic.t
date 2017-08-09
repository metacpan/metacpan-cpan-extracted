#!perl

use 5.010001;
use strict;
use warnings;

use Getopt::Long::EvenLess qw(GetOptions GetOptionsFromArray);
use Test::Exception;
use Test::More 0.98;

my %r;

subtest "basics" => sub {
    %r=(); test_getopt(
        name => 'case sensitive',
        args => ["foo"=>sub{}],
        argv => ["--Foo"],
        success => 0,
    );
    %r=(); test_getopt(
        name => 'empty argv',
        args => ["foo=s"=>sub{$r{foo}=$_[1]}],
        argv => [],
        success => 1,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => '-- (1)',
        args => ["foo=s"=>sub{$r{foo}=$_[1]}],
        argv => ["--"],
        success => 1,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => '-- (2)',
        args => ["foo=s"=>sub{$r{foo}=$_[1]}],
        argv => ["--", "--foo"],
        success => 1,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => ["--foo"],
    );

    %r=(); test_getopt(
        name => 'unknown argument -> error (1)',
        args => ["bar=s"=>sub{$r{bar}=$_[1]}, "foo=s"=>sub{$r{foo}=$_[1]}],
        argv => ["--bar", "--val", "--qux"],
        success => 0,
        test_res => sub { is_deeply(\%r, {bar=>"--val"}) },
        remaining => ["--qux"],
    );
    %r=(); test_getopt(
        name => 'unknown argument -> not error under pass_through',
        args => ["bar=s"=>sub{$r{bar}=$_[1]}, "foo=s"=>sub{$r{foo}=$_[1]}],
        argv => ["--bar", "--val", "--qux"],
        config => ['pass_through'],
        success => 1,
        test_res => sub { is_deeply(\%r, {bar=>"--val"}) },
        remaining => ["--qux"],
    );
    %r=(); test_getopt(
        name => 'unknown argument -> error (2)',
        args => ["bar=s"=>sub{$r{bar}=$_[1]}, "foo=s"=>sub{$r{foo}=$_[1]}],
        argv => ["--qux", "--bar", "--val"],
        success => 0,
        test_res => sub { is_deeply(\%r, {bar=>"--val"}) },
        remaining => ["--qux"],
    );
    %r=(); test_getopt(
        name => 'prefix matching',
        args => ["bar=s"=>sub{$r{bar}=$_[1]}],
        argv => ["--ba", "--val"],
        success => 1,
        test_res => sub { is_deeply(\%r, {bar=>"--val"}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => 'ambiguous prefix -> error',
        args => ["bar=s"=>sub{$r{bar}=$_[1]}, "baz=s"=>sub{$r{baz}=$_[1]}],
        argv => ["--ba", "--val"],
        success => 0,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => ['--ba', '--val'],
    );
    %r=(); test_getopt(
        name => 'ambiguous prefix -> not error under pass_through',
        args => ["bar=s"=>sub{$r{bar}=$_[1]}, "baz=s"=>sub{$r{baz}=$_[1]}],
        argv => ["--ba", "--val"],
        config => ['pass_through'],
        success => 1,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => ['--ba', '--val'],
    );
    %r=(); test_getopt(
        name => 'missing required argument -> error',
        args => ["bar=s"=>sub{$r{bar}=$_[1]}],
        argv => ["--bar"],
        success => 0,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => [],
    );
};

subtest "type" => sub {
    %r=(); test_getopt(
        name => 'basics',
        args => ["foo=s"=>sub{$r{foo}=$_[1]}, "bar=i"=>sub{$r{bar}=$_[1]},"baz=f"=>sub{$r{baz}=$_[1]},
             ],
        argv => ["--foo", 1, "--bar", 2, "--baz", 3],
        success => 1,
        test_res => sub { is_deeply(\%r, {foo=>1, bar=>2, baz=>3}) },
        remaining => [],
    );
};

subtest "desttype" => sub {
    %r=(); test_getopt(
        name => 'array',
        args => ['foo=s@'=>sub{$r{foo} //= []; push @{$r{foo}}, $_[1]}],
        argv => ["--foo", 2, "--foo", 1, "--foo", 3],
        success => 1,
        test_res => sub { is_deeply(\%r, {foo=>[2,1,3]}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => 'hash',
        args => ['foo=s%'=>sub{$r{foo} //= {}; $_[1] =~ /([^=]+)=(.*)/; $r{foo}{$1} = $2 }],
        argv => ["--foo", "a=1", "--foo", "b=2", "--foo=c=3"],
        success => 1,
        test_res => sub { is_deeply(\%r, {foo=>{a=>1, b=>2, c=>3}}) },
        remaining => [],
    );
};

subtest "gnu compat" => sub {
    %r=(); test_getopt(
        name => '(1)',
        args => ["foo=s"=>sub{$r{foo}=$_[1]}],
        argv => ["--foo=x", "y"],
        success => 1,
        test_res => sub { is_deeply(\%r, {foo=>"x"}) },
        remaining => ["y"],
    );
    %r=(); test_getopt(
        name => '(2)',
        args => ["foo=s"=>sub{$r{foo}=$_[1]}],
        argv => ["--foo=", "y"],
        success => 1,
        test_res => sub { is_deeply(\%r, {foo=>""}) },
        remaining => ["y"],
    );
};

subtest "bundling" => sub {
    %r=(); test_getopt(
        name => '(1)',
        args => ["foo|f=s"=>sub{$r{foo}=$_[1]}, "bar|b"=>sub{$r{bar}=$_[1]}],
        argv => ["-fb"],
        success => 1,
        test_res => sub { is_deeply(\%r, {foo=>"b"}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => '(2)',
        args => ["foo|f=s"=>sub{$r{foo}=$_[1]}, "bar|b"=>sub{$r{bar}=$_[1]}],
        argv => ["-bfb"],
        success => 1,
        test_res => sub { is_deeply(\%r, {foo=>"b", bar=>1}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => 'option argument from next argument',
        args => ["foo|f=s"=>sub{$r{foo}=$_[1]}, "bar|b"=>sub{$r{bar}=$_[1]}],
        argv => ["-bf", "b"],
        success => 1,
        test_res => sub { is_deeply(\%r, {foo=>"b", bar=>1}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => 'missing required argument -> error',
        args => ["foo|f=s"=>sub{$r{foo}=$_[1]}, "bar|b"=>sub{$r{bar}=$_[1]}],
        argv => ["-bf"],
        success => 0,
        test_res => sub { is_deeply(\%r, {bar=>1}) },
        remaining => [],
    );
};

subtest "config:pass_through" => sub {
    %r=(); test_getopt(
        name => 'unknown long option & argument not consumed',
        args => ["foo|f=s"=>sub{$r{foo}=$_[1]}],
        argv => [qw/--bar x y/],
        config => ['pass_through'],
        success => 1,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => [qw/--bar x y/],
    );
    %r=(); test_getopt(
        name => 'ambiguous long option not consumed',
        args => ["bar=s"=>sub{$r{bar}=$_[1]}, "baz=s"=>sub{$r{baz}=$_[1]}, ],
        argv => [qw/--ba x/],
        config => ['pass_through'],
        success => 1,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => [qw/--ba x/],
    );
    %r=(); test_getopt(
        name => 'unknown short option not consumed',
        args => ["foo|f=s"=>sub{$r{foo}=$_[1]}],
        argv => [qw/-g/],
        config => ['pass_through'],
        success => 1,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => [qw/-g/],
    );
};

subtest "config:auto_abbrev" => sub {
    %r=(); test_getopt(
        name => 'auto_abbrev=1',
        args => ["foo=s"=>sub{$r{foo}=$_[1]}],
        argv => [qw/--fo x/],
        success => 1,
        test_res => sub { is_deeply(\%r, {foo=>'x'}) },
        remaining => [qw//],
    );
    %r=(); test_getopt(
        name => 'auto_abbrev=0',
        args => ["foo=s"=>sub{$r{foo}=$_[1]}],
        argv => [qw/--fo x/],
        config => ['no_auto_abbrev'],
        success => 0,
        test_res => sub { is_deeply(\%r, {}) },
        remaining => [qw/--fo x/],
    );
};

sub test_getopt {
    my %args = @_;

    my $name = $args{name} // do {
        my %spec = %{ @{$args{args}} };
        my $name .= "spec:[".join(", ", sort keys %spec)."]";
        $name .= " argv:[".join("", @{$args{argv}})."]";
        $name;
    };

    subtest $name => sub {
        my @argv = @{ $args{argv} };

        my $save_conf; $save_conf = Getopt::Long::EvenLess::Configure(@{ $args{config} }) if $args{config};
        my $res;
        eval { $res = GetOptionsFromArray(\@argv, @{ $args{args} }) };
        Getopt::Long::EvenLess::Configure($save_conf) if $save_conf;

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

        if ($args{test_res}) {
            $args{test_res}->();
        }

        if ($args{remaining}) {
            is_deeply(\@argv, $args{remaining}, "remaining")
                or diag explain \@argv;
        }

      RETURN:
    };
}

DONE_TESTING:
done_testing;
