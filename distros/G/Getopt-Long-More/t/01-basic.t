#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Getopt::Long::More qw(optspec);

# XXX test exports

{
    my $opts = {};
    test_getoptions(
        name => 'empty opts spec',
        opts_spec => [],
        argv => [qw/a b/],
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw/a b/],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'unknown opt -> fail',
        opts_spec => [],
        argv => [qw/--help a b/],
        is_success => 0,
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw/a b/],
    );
}

{
    my $opts = {};
    test_getoptions(
        name => 'config: pass_through',
        config => [qw/pass_through/],
        opts_spec => [],
        argv => [qw/--help a b/],
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw/--help a b/],
    );
}

{
    my $opts = {};
    test_getoptions(
        name => 'basic',
        opts_spec => ['foo=s' => \$opts->{foo}],
        argv => [qw/--foo bar/],
        opts => $opts,
        expected_opts => {foo => "bar"},
        expected_argv => [qw//],
    );
}

subtest "optspec: no property is required" => sub {
    lives_ok { optspec() };
};

subtest "optspec: unknown property -> dies" => sub {
    dies_ok { optspec(foo=>1) };
};

subtest "optspec: extra properties allowed" => sub {
    lives_ok { optspec(handler=>sub{}, _foo=>1, 'x.bar'=>2, _=>{baz=>3}, x=>{qux=>4}) };
};

subtest "optspec: invalid extra properties -> dies" => sub {
    dies_ok { optspec(handler=>sub{}, 'x.'=>1) };
};

{
    my $opts = {};
    test_getoptions(
        name => 'optspec: default (unset)',
        opts_spec => ['foo=s' => optspec(handler => \$opts->{foo}, default => "bar")],
        argv => [qw//],
        opts => $opts,
        expected_opts => {foo => "bar"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: default (set)',
        opts_spec => ['foo=s' => optspec(handler => \$opts->{foo}, default => "bar")],
        argv => [qw/--foo qux/],
        opts => $opts,
        expected_opts => {foo => "qux"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: default (on <> -> ignored)',
        opts_spec => ['<>' => optspec(handler => sub{}, default => ["a","b"])],
        argv => [qw//],
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw//],
    );
}

{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (unset)',
        opts_spec => ['foo=s' => optspec(handler => \$opts->{foo}, required => 1)],
        argv => [qw//],
        dies => 1,
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (set)',
        opts_spec => ['foo=s' => optspec(handler => \$opts->{foo}, required => 1)],
        argv => [qw/--foo=bar/],
        opts => $opts,
        expected_opts => {foo => "bar"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (on <>, unset)',
        opts_spec => ['<>' => optspec(handler => sub{}, required => 1)],
        argv => [qw//],
        dies => 1,
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (set)',
        opts_spec => ['<>' => optspec(handler => sub{}, required => 1)],
        argv => [qw/a b/],
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw//],
    );
}

{
    my $opts = {};
    test_getoptions(
        name => 'basic: with hash-storage',
        opts_spec => [$opts, 'foo=s' => \$opts->{foo}],
        argv => [qw/--foo bar/],
        opts => $opts,
        expected_opts => {foo => "bar"},
        expected_argv => [qw//],
    );
}

{
    my $opts = {};
    test_getoptions(
        name => 'basic: mixed implict/explicit linkage',
        opts_spec =>  [
          'foo=s', \$opts->{foo},
          'bar=s',
          'baz=s', \$opts->{baz},
          'gaz=s', \$opts->{gaz},
        ],
        argv => [qw/--foo boo --baz boz --gaz gez/],
        opts => $opts,
        expected_opts => {foo => "boo", baz => "boz", gaz => "gez"},
        expected_argv => [qw//],
    );
}

{
    my $opts = {};
    test_getoptions(
        name => 'optspec: mixed implict/explicit linkage',
        opts_spec =>  [
          'foo=s', optspec(handler => \$opts->{foo} ),
          'bar=s',
          'baz=s', optspec(handler => \$opts->{baz} ),
          'gaz=s', \$opts->{gaz},
        ],
        argv => [qw/--foo boo --baz boz --gaz gez/],
        opts => $opts,
        expected_opts => {foo => "boo", baz => "boz", gaz => "gez"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: with "hash-storage"',
        opts_spec => [
          $opts,
          'foo=s', optspec(handler => \$opts->{foo} ),
          'bar=s',
        ],
        argv => [qw/--foo boo --bar bur/],
        opts => $opts,
        expected_opts => {foo => "boo", bar => "bur"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: mixed implict/explicit linkage (with "hash-storage")',
        opts_spec => [
          $opts,
          'foo=s', optspec(handler => \$opts->{foo} ),
          'bar=s',
          'baz=s', optspec(handler => \$opts->{baz} ),
          'gaz=s', \$opts->{gaz},
        ],
        argv => [qw/--foo boo --bar bur --baz boz --gaz gez/],
        opts => $opts,
        expected_opts => {foo => "boo", bar => "bur", baz => "boz", gaz => "gez" },
        expected_argv => [qw//],
    );
}

# XXX test summary
# XXX test pod

done_testing;

sub test_getoptions {
    my %args = @_;
    my @argv = @{ $args{argv} };
    subtest +($args{name} // join(" ", @argv)) => sub {
        my $old_conf;
        $old_conf = Getopt::Long::More::Configure(@{$args{config}})
            if $args{config};
        my $res;
        eval {
            $res = Getopt::Long::More::GetOptionsFromArray(
                \@argv,
                @{ $args{opts_spec} },
            );
        };
        my $err = $@;

        {
            if ($args{dies}) {
                ok($err, "dies");
                last;
            } else {
                ok(!$err, "doesn't die") or do {
                    diag "err=$err";
                    last;
                };
            }
            if ($args{is_success} // 1) {
                ok($res, "success");
            } else {
                ok(!$res, "fail");
            }
            if ($args{expected_opts}) {
                is_deeply($args{opts}, $args{expected_opts}, "options")
                    or diag explain $args{opts};
            }
            if ($args{expected_argv}) {
                is_deeply(\@argv, $args{expected_argv}, "remaining argv")
                    or diag explain \@argv;
            }
            if ($args{posttest}) {
                $args{posttest}->();
            }
        }

        Getopt::Long::More::Configure($old_conf) if $old_conf;
    };
}
