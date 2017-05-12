#!/usr/bin/env perl

use strict;
use warnings;

use Carp qw(confess);
use Test::More;

# arbitrary Getopt::Long option name
# (parsing depends on the params passed to GetModule, not the option name)
use constant OPTION_NAME => 'module';

sub pp($) { Getopt::Module::_pp($_[0]) }

=begin comment

    my $spec = {
        args      => \@args,
        eval      => $eval,
        method    => $method,
        module    => $module,
        name      => $name,
        statement => $statement,
        value     => $value,
    };

=end comment

=cut

sub _qw_to_split($) {
    my $evals = shift;
    my $ref = ref($evals);

    $evals = [ $evals ] unless ($ref);

    my $spaces_to_commas = sub($) {
        join(',', split(qr{\s+}, shift));
    };

    my $qw_to_split = sub($) {
        my $NUL = "\0";
        sprintf('split(/,/,q%s%s%s)', $NUL, $spaces_to_commas->($_[0]), $NUL);
    };

    my $rv = [
        map {
            my $eval = $_;
            $eval =~ s{\bqw\(([^)]+)\)}{$qw_to_split->("$1")}eg;
            $eval;
        } @$evals
    ];

    return $ref ? $rv : $rv->[0];
}

sub is_parsed {
    my $target = shift;
    my $_want = pop;
    my $value = pop;
    my $options = {};
    my $tb = Test::More->builder;

    # report errors with caller's line number
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    confess 'target must be a ref' unless (ref $target);

    if (@_) {
        $options = @_ == 1 ? shift : { @_ };
    }

    confess 'options must be a hashref' unless (ref($options) eq 'HASH');

    my $ref = ref($_want);
    my $want;

    # $want can be the expected target, or a subset of the spec hash returned
    # by GetModule. if it's the former, convert it into the latter
    # XXX squashed bug: watch out for perl flakiness if trying to do (something like)
    # this without an intermediary temp value: $want = { target => \$want }
    if (($ref eq 'HASH') && ($_want->{eval})) {
        $_want->{eval} = _qw_to_split($_want->{eval});
        $want = $_want;
    } else {
        if ($ref) {
            if ($ref eq 'ARRAY') {
                $_want = _qw_to_split($_want);
            } elsif ($ref eq 'HASH') {
                for my $key (keys %$_want) {
                    $_want->{$key} = _qw_to_split($_want->{$key});
                }
            } else {
                die "unexpected want type: $ref", $/;
            }

            $want = { target => $_want };
        } else {
            my $eval = _qw_to_split($_want);
            $want = { target => \$eval };
        }
    }

    $want->{name} = OPTION_NAME;
    $want->{value} = $value;

    my $old_target = pp($target);
    my $got = GetModule($target, $options)->(OPTION_NAME, $value);

    isa_ok $got, 'HASH', 'GetModule(...) return value';

    # add a fake field to the return value so we can verify side effects
    $got->{target} = $target;

    # field sort order: name < value < other fields
    my $pos = sub { { name => 1, value => 2 }->{$_[0]} || 3 };

    for my $key (sort { ($pos->($a) <=> $pos->($b)) || ($a cmp $b) } keys %$want) {
        my $test_name = sprintf(
            "GetModule(%s, %s)->(%s, %s)->{%s} is %s",
            $old_target,
            pp($options),
            pp(OPTION_NAME),
            pp($value),
            $key,
            pp($want->{$key})
        );

        my $ok = is_deeply(
            $got->{$key},
            $want->{$key},
            $test_name
        );

        unless ($ok) {
            warn 'got: ',  pp($got), $/;
            warn 'want: ', pp($want), $/;
        }
    }
}

use_ok('Getopt::Module', 'GetModule');

# SCALARREF

my @array = (undef) x 10;
is_parsed(\$array[0], 'Foo', 'use Foo;');
is_parsed(\$array[1], '-Foo', 'no Foo;');
is_parsed(\$array[2], 'Foo=foo,bar', 'use Foo qw(foo bar);');
is_parsed(\$array[3], '-Foo=foo,bar', 'no Foo qw(foo bar);');
is_parsed(\$array[4], 'Foo { bar => $baz }', 'use Foo { bar => $baz };');
is_parsed(\$array[5], '-Foo { bar => $baz }', 'no Foo { bar => $baz };');
is_parsed(\$array[6], no_import => 0, 'Foo', 'use Foo;');
is_parsed(\$array[7], no_import => 1, 'Foo', 'use Foo ();');
is_parsed(\$array[8], no_import => 0, '-Foo', 'no Foo;');
is_parsed(\$array[9], no_import => 1, '-Foo', 'no Foo ();');

is_parsed(\my $scalar1, 'Foo', 'use Foo;');
is_parsed(\$scalar1,    'Foo', 'use Foo; use Foo;');
is_parsed(\my $scalar2, 'Foo', 'use Foo;');

my $scalar3 = '>';
is_parsed(\$scalar3, 'Foo', '> use Foo;');
is_parsed(\$scalar3, 'Foo', '> use Foo; use Foo;');

is_parsed(\my $scalar4, separator => '|', 'Foo', 'use Foo;');
is_parsed(\$scalar4,    separator => '|', 'Foo', 'use Foo;|use Foo;');

is_parsed(\my $scalar5, 'Foo=foo', 'use Foo qw(foo);');
is_parsed(\my $scalar6, 'Foo=foo,bar', 'use Foo qw(foo bar);');
is_parsed(\my $scalar7, 'Foo=foo,bar,baz', 'use Foo qw(foo bar baz);');

# ARRAYREF

is_parsed([], 'Foo', [ 'use Foo;' ]);
is_parsed([], '-Foo', [ 'no Foo;' ]);
is_parsed([], 'Foo=bar', [ 'use Foo qw(bar);' ]);
is_parsed([], '-Foo=bar', [ 'no Foo qw(bar);' ]);
is_parsed([], 'Foo=bar,baz', [ 'use Foo qw(bar baz);' ]);
is_parsed([], '-Foo=bar,baz', [ 'no Foo qw(bar baz);' ]);
is_parsed([], 'Foo { bar => $baz }', [ 'use Foo { bar => $baz };' ]);
is_parsed([], '-Foo { bar => $baz }', [ 'no Foo { bar => $baz };' ]);
is_parsed([], no_import => 0, 'Foo', [ 'use Foo;' ]);
is_parsed([], no_import => 1, 'Foo', [ 'use Foo ();' ]);
is_parsed([], no_import => 1, 'Foo=bar', [ 'use Foo qw(bar);' ]);
is_parsed([], no_import => 1, 'Foo=bar,baz', [ 'use Foo qw(bar baz);' ]);
is_parsed([], no_import => 0, '-Foo', [ 'no Foo;' ]);
is_parsed([], no_import => 1, '-Foo', [ 'no Foo ();' ]);
is_parsed([], no_import => 1, '-Foo=bar', [ 'no Foo qw(bar);' ]);
is_parsed([], no_import => 1, '-Foo=bar,baz', [ 'no Foo qw(bar baz);' ]);

my $array = [];

is_parsed($array, 'Foo', [ 'use Foo;' ]);
is_parsed($array, 'Foo=bar,baz', [ 'use Foo;', 'use Foo qw(bar baz);' ]);
is_parsed($array, '-Foo', [ 'use Foo;', 'use Foo qw(bar baz);', 'no Foo;' ]);
is_parsed($array, '-Foo=bar,baz',
    [ 'use Foo;', 'use Foo qw(bar baz);', 'no Foo;', 'no Foo qw(bar baz);' ]
);
is_parsed($array, no_import => 0, 'Foo',
    [ 'use Foo;', 'use Foo qw(bar baz);', 'no Foo;', 'no Foo qw(bar baz);', 'use Foo;' ]
);
is_parsed($array, no_import => 1, 'Foo',
    [ 'use Foo;', 'use Foo qw(bar baz);', 'no Foo;', 'no Foo qw(bar baz);', 'use Foo;', 'use Foo ();' ]
);
is_parsed($array, no_import => 0, '-Foo',
    [ 'use Foo;', 'use Foo qw(bar baz);', 'no Foo;', 'no Foo qw(bar baz);', 'use Foo;', 'use Foo ();', 'no Foo;' ]
);
is_parsed($array, no_import => 1, '-Foo',
    [ 'use Foo;', 'use Foo qw(bar baz);', 'no Foo;', 'no Foo qw(bar baz);', 'use Foo;', 'use Foo ();', 'no Foo;', 'no Foo ();' ]
);

# HASHREF

is_parsed({}, 'Foo', { Foo => [ 'use Foo;' ] });
is_parsed({}, '-Foo', { Foo => [ 'no Foo;' ] });
is_parsed({}, 'Foo { bar => $baz }', { Foo => [ 'use Foo { bar => $baz };' ] });
is_parsed({}, '-Foo { bar => $baz }', { Foo => [ 'no Foo { bar => $baz };' ] });
is_parsed({}, 'Foo=bar', { Foo => [ 'use Foo qw(bar);' ] });
is_parsed({}, '-Foo=bar', { Foo => [ 'no Foo qw(bar);' ] });
is_parsed({}, 'Foo=bar,baz', { Foo => [ 'use Foo qw(bar baz);' ] });
is_parsed({}, '-Foo=bar,baz', { Foo => [ 'no Foo qw(bar baz);' ] });
is_parsed({}, no_import => 0, 'Foo', { Foo => [ 'use Foo;' ] });
is_parsed({}, no_import => 0, '-Foo',  { Foo => [ 'no Foo;' ] });
is_parsed({}, no_import => 1, 'Foo', { Foo => [ 'use Foo ();' ] });
is_parsed({}, no_import => 1, '-Foo', { Foo => [ 'no Foo ();' ] });

my $hash = {};

is_parsed($hash, 'Foo', { Foo => [ 'use Foo;' ] });
is_parsed($hash, 'Foo=bar,baz', { Foo => [ 'use Foo;', 'use Foo qw(bar baz);' ] });
is_parsed($hash, '-Bar',
    { Foo => [ 'use Foo;', 'use Foo qw(bar baz);' ], Bar => [ 'no Bar;' ] }
);
is_parsed($hash, '-Bar=baz,quux',
    { Foo => [ 'use Foo;', 'use Foo qw(bar baz);' ], Bar => [ 'no Bar;', 'no Bar qw(baz quux);' ] }
);
is_parsed($hash, no_import => 0, '-Baz',
    { Foo => [ 'use Foo;', 'use Foo qw(bar baz);' ], Bar => [ 'no Bar;', 'no Bar qw(baz quux);' ], Baz => [ 'no Baz;' ] }
);
is_parsed($hash, no_import => 1, 'Baz',
    { Foo => [ 'use Foo;', 'use Foo qw(bar baz);' ], Bar => [ 'no Bar;', 'no Bar qw(baz quux);' ], Baz => [ 'no Baz;' , 'use Baz ();' ] }
);

# CODEREF

my $sub = sub {
    is (scalar(@_), 3);
    is ref($_[0]), '';
    is ref($_[1]), '';
    # $_[2] is already checked in is_parsed
};

is_parsed $sub, 'Foo', {
    args      => undef,
    eval      => 'use Foo;',
    method    => 'import',
    module    => 'Foo',
    name      => 'module',
    statement => 'use',
    value     => 'Foo',
};

is_parsed $sub, '-Foo', {
    args      => undef,
    eval      => 'no Foo;',
    method    => 'unimport',
    module    => 'Foo',
    name      => 'module',
    statement => 'no',
    value     => '-Foo',
};

is_parsed $sub, 'Foo { bar => $baz }', {
    args      => '{ bar => $baz }',
    eval      => 'use Foo { bar => $baz };',
    method    => 'import',
    module    => 'Foo',
    name      => 'module',
    statement => 'use',
    value     => 'Foo { bar => $baz }',
};

is_parsed $sub, '-Foo { bar => $baz }', {
    args      => '{ bar => $baz }',
    eval      => 'no Foo { bar => $baz };',
    method    => 'unimport',
    module    => 'Foo',
    name      => 'module',
    statement => 'no',
    value     => '-Foo { bar => $baz }',
};

is_parsed $sub, 'Foo=bar,baz', {
    args      => 'bar,baz',
    eval      => 'use Foo qw(bar baz);',
    method    => 'import',
    module    => 'Foo',
    name      => 'module',
    statement => 'use',
    value     => 'Foo=bar,baz',
};

is_parsed $sub, '-Foo=bar,baz', {
    args      => 'bar,baz',
    eval      => 'no Foo qw(bar baz);',
    method    => 'unimport',
    module    => 'Foo',
    name      => 'module',
    statement => 'no',
    value     => '-Foo=bar,baz',
};

is_parsed $sub, no_import => 0, 'Foo', {
    args      => undef,
    eval      => 'use Foo;',
    method    => 'import',
    module    => 'Foo',
    name      => 'module',
    statement => 'use',
    value     => 'Foo',
};

is_parsed $sub, no_import => 1, 'Foo', {
    args      => undef,
    eval      => 'use Foo ();',
    method    => 'import',
    module    => 'Foo',
    name      => 'module',
    statement => 'use',
    value     => 'Foo',
};

is_parsed $sub, no_import => 0, '-Foo', {
    args      => undef,
    eval      => 'no Foo;',
    method    => 'unimport',
    module    => 'Foo',
    name      => 'module',
    statement => 'no',
    value     => '-Foo',
};

is_parsed $sub, no_import => 1, '-Foo', {
    args      => undef,
    eval      => 'no Foo ();',
    method    => 'unimport',
    module    => 'Foo',
    name      => 'module',
    statement => 'no',
    value     => '-Foo',
};

done_testing;
