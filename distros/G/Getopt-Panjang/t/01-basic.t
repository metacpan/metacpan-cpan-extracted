#!perl

use 5.010;
use strict;
use warnings;

use Getopt::Panjang qw(get_options);
use Test::More 0.98;

my %r;

subtest "basics" => sub {
    %r=(); test_getopt(
        name => 'case sensitive',
        args => {
            spec=>{"foo"=>sub{}},
            argv=>['--Foo'],
        },
        status => 500,
        unknown_opts => {'Foo'=>1},
    );
    %r=(); test_getopt(
        name => 'empty argv',
        args => {
            spec=>{"foo=s"=>sub{my %a=@_; $r{foo}=$a{value}}},
            argv=>[],
        },
        status => 200,
        posttest => sub { is_deeply(\%r, {}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => '-- (1)',
        args => {
            spec=>{"foo=s"=>sub{my %a=@_; $r{foo}=$a{value}}},
            argv => ["--"],
        },
        status => 200,
        posttest => sub { is_deeply(\%r, {}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => '-- (2)',
        args => {
            spec => {"foo=s"=>sub{my %a=@_; $r{foo}=$a{value}}},
            argv => ["--", "--foo"],
        },
        status => 200,
        posttest => sub { is_deeply(\%r, {}) },
        remaining => ["--foo"],
    );

    %r=(); test_getopt(
        name => 'unknown argument -> error (1)',
        args => {
            spec => {"bar=s"=>sub{my %a=@_; $r{bar}=$a{value}},
                     "foo=s"=>sub{my %a=@_; $r{foo}=$a{value}}},
            argv => ["--bar", "--val", "--qux"],
        },
        status => 500,
        unknown_opts => {qux=>1},
        posttest => sub { is_deeply(\%r, {bar=>"--val"}) },
        remaining => ["--qux"],
    );
    %r=(); test_getopt(
        name => 'unknown argument -> error (2)',
        args => {
            spec => {"bar=s"=>sub{my %a=@_; $r{bar}=$a{value}},
                     "foo=s"=>sub{my %a=@_; $r{foo}=$a{value}}},
            argv => ["--qux", "--bar", "--val"],
        },
        status => 500,
        posttest => sub { is_deeply(\%r, {bar=>"--val"}) },
        remaining => ["--qux"],
    );
    %r=(); test_getopt(
        name => 'prefix matching',
        args => {
            spec => {"bar=s"=>sub{my %a=@_; $r{bar}=$a{value}}},
            argv => ["--ba", "--val"],
        },
        status => 200,
        posttest => sub { is_deeply(\%r, {bar=>"--val"}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => 'ambiguous prefix -> error',
        args => {
            spec => {"bar=s"=>sub{my %a=@_; $r{bar}=$a{value}},
                     "baz=s"=>sub{my %a=@_; $r{baz}=$a{value}}},
            argv => ["--ba", "--val"],
        },
        status => 500,
        ambiguous_opts => {ba=>['bar', 'baz']},
        posttest => sub { is_deeply(\%r, {}) },
        remaining => ['--val'],
    );
    %r=(); test_getopt(
        name => 'missing required argument -> error',
        args => {
            spec => {"bar=s"=>sub{my %a=@_; $r{bar}=$a{value}}},
            argv => ["--bar"],
        },
        status => 500,
        val_missing_opts => {bar=>1},
        posttest => sub { is_deeply(\%r, {}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => 'handler dies -> error',
        args => {
            spec => {"bar=s"=>sub{die "died\n"}},
            argv => ["--bar", 1],
        },
        status => 500,
        val_invalid_opts => {bar=>"Invalid value for option 'bar': died\n"},
        posttest => sub { is_deeply(\%r, {}) },
        remaining => [],
    );
};

subtest "type" => sub {
    %r=(); test_getopt(
        name => 'basics',
        args => {
            spec => {"foo=s"=>sub{my %a=@_; $r{foo}=$a{value}},
                     "bar=i"=>sub{my %a=@_; $r{bar}=$a{value}},
                     "baz=f"=>sub{my %a=@_; $r{baz}=$a{value}}},
            argv => ["--foo", 1, "--bar", 2, "--baz", 3],
        },
        status => 200,
        posttest => sub { is_deeply(\%r, {foo=>1, bar=>2, baz=>3}) },
        remaining => [],
    );
};

subtest "desttype" => sub {
    %r=(); test_getopt(
        name => 'basics',
        args => {
            spec => {'foo=s@'=>sub{my %a=@_; $r{foo} //= []; push @{$r{foo}}, $a{value}}},
            argv => ["--foo", 2, "--foo", 1, "--foo", 3],
        },
        status => 200,
        posttest => sub { is_deeply(\%r, {foo=>[2,1,3]}) },
        remaining => [],
    );
};

subtest "gnu compat" => sub {
    %r=(); test_getopt(
        name => '(1)',
        args => {
            spec => {"foo=s"=>sub{my %a=@_; $r{foo}=$a{value}}},
            argv => ["--foo=x", "y"],
        },
        status => 200,
        posttest => sub { is_deeply(\%r, {foo=>"x"}) },
        remaining => ["y"],
    );
    %r=(); test_getopt(
        name => '(2)',
        args => {
            spec => {"foo=s"=>sub{my %a=@_; $r{foo}=$a{value}}},
            argv => ["--foo=", "y"],
        },
        status => 500,
        posttest => sub { is_deeply(\%r, {}) },
        remaining => ["y"],
    );
};

subtest "bundling" => sub {
    %r=(); test_getopt(
        name => '(1)',
        args => {
            spec => {"foo|f=s"=>sub{my %a=@_; $r{foo}=$a{value}},
                     "bar|b"=>sub{my %a=@_; $r{bar}=$a{value}}},
            argv => ["-fb"],
        },
        status => 200,
        posttest => sub { is_deeply(\%r, {foo=>"b"}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => '(2)',
        args => {
            spec => {"foo|f=s"=>sub{my %a=@_; $r{foo}=$a{value}},
                     "bar|b"=>sub{my %a=@_; $r{bar}=$a{value}}},
            argv => ["-bfb"],
       },
        status => 200,
        posttest => sub { is_deeply(\%r, {foo=>"b", bar=>1}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => 'option argument from next argument',
        args => {
            spec => {"foo|f=s"=>sub{my %a=@_; $r{foo}=$a{value}},
                     "bar|b"=>sub{my %a=@_; $r{bar}=$a{value}}},
            argv => ["-bf", "b"],
        },
        status => 200,
        posttest => sub { is_deeply(\%r, {foo=>"b", bar=>1}) },
        remaining => [],
    );
    %r=(); test_getopt(
        name => 'missing required argument -> error',
        args => {
            spec => {"foo|f=s"=>sub{my %a=@_; $r{foo}=$a{value}},
                     "bar|b"=>sub{my %a=@_; $r{bar}=$a{value}}},
            argv => ["-bf"],
        },
        status => 500,
        val_missing_opts => {f=>1},
        posttest => sub { is_deeply(\%r, {bar=>1}) },
        remaining => [],
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
        my $res = get_options(%{$args{args}});

        if (defined($args{status})) {
            is($res->[0], $args{status}, "status=$args{status}");
        }

        if ($args{remaining}) {
            is_deeply($res->[3]{'func.remaining_argv'}, $args{remaining}, "remaining")
                or diag explain $res->[3]{'func.remaining_args'};
        }
        if ($args{ambiguous_opts}) {
            is_deeply($res->[3]{'func.ambiguous_opts'}, $args{ambiguous_opts}, "ambiguous_opts")
                or diag explain $res->[3]{'func.ambiguous_opts'};
        }
        if ($args{unknown_opts}) {
            is_deeply($res->[3]{'func.unknown_opts'}, $args{unknown_opts}, "unknown_opts")
                or diag explain $res->[3]{'func.unknown_opts'};
        }
        if ($args{val_missing_opts}) {
            is_deeply($res->[3]{'func.val_missing_opts'}, $args{val_missing_opts}, "val_missing_opts")
                or diag explain $res->[3]{'func.val_missing_opts'};
        }
        if ($args{val_invalid_opts}) {
            is_deeply($res->[3]{'func.val_invalid_opts'}, $args{val_invalid_opts}, "val_invalid_opts")
                or diag explain $res->[3]{'func.val_invalid_opts'};
        }

        if ($args{posttest}) {
            $args{posttest}->();
        }

      RETURN:
    };
}

DONE_TESTING:
done_testing;
