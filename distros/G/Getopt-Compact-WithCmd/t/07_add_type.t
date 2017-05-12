use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

sub create_obj {
    my ($argv, $opts) = @_;
    Getopt::Compact::WithCmd->new_from_string($argv,
        global_struct => { foo => $opts },
    );
}

Getopt::Compact::WithCmd->add_type(Eval => Str => sub {
    my $res = eval "$_[0]";
    die "$_[0]: $@\n" if $@;
    return $res;
});

subtest 'scalar' => sub {
    my $go = create_obj(q|--foo "{ bar => 'baz' }"|, { type => 'Eval' });
    is_deeply $go->opts->{foo}, { bar => 'baz' };
    is_deeply $go->args, [];
};

subtest 'array' => sub {
    my $go = create_obj(q|--foo "{ bar => 'baz' }", --foo "[qw/hoge/]"|, {
        type => 'Array[Eval]',
    });
    is_deeply $go->opts->{foo}, [ { bar => 'baz' }, [qw/hoge/] ];
    is_deeply $go->args, [];
};

subtest 'hash' => sub {
    my $go = create_obj(q|--foo "a={ bar => 'baz' }" --foo "b={ hoge => 'fuga' }"|, {
        type => 'Hash[Eval]',
    });
    is_deeply $go->opts->{foo}, { a => { bar => 'baz' }, b => { hoge => 'fuga' } };
    is_deeply $go->args, [];
};

subtest 'hash (exception)' => sub {
    my $go = eval {
        create_obj(q|--foo "[qw/bar/]"|, { type => 'Hash[Eval]' });
    };
    my $error = quotemeta 'Option foo, key "[qw/bar/]", requires a value';
    like $go->error, qr/$error/;
};

subtest 'scalar dest on $foo' => sub {
    my $go = create_obj(q|--foo "{ bar => 'baz' }"|, {
        type => 'Eval',
        dest => \my $foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply $foo, { bar => 'baz' };
    is_deeply $go->args, [];
};

subtest 'scalar dest on $foo (defined)' => sub {
    my $foo = 'bar';
    my $go = create_obj(q|--foo "{ bar => 'baz' }"|, {
        type => 'Eval',
        dest => \$foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply $foo, { bar => 'baz' };
    is_deeply $go->args, [];
};

subtest 'scalar dest on @foo' => sub {
    my $go = create_obj(q|--foo "{ bar => 'baz' }"|, {
        type => 'Eval',
        dest => \my @foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \@foo, [ { bar => 'baz' } ];
    is_deeply $go->args, [];
};

subtest 'scalar dest on @foo (defined)' => sub {
    my @foo = qw(bar);
    my $go = create_obj(q|--foo "{ bar => 'baz' }"|, {
        type => 'Eval',
        dest => \@foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \@foo, [ { bar => 'baz' } ];
    is_deeply $go->args, [];
};

subtest 'scalar dest on %foo' => sub {
    my $go = create_obj(q|--foo "a={ bar => 'baz' }"|, {
        type => 'Eval',
        dest => \my %foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \%foo, { a => { bar => 'baz' } };
    is_deeply $go->args, [];
};

subtest 'scalar dest on %foo (defined)' => sub {
    my %foo = (foo => 'bar');
    my $go = create_obj(q|--foo "a={ bar => 'baz' }"|, {
        type => 'Eval',
        dest => \%foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \%foo, { a => { bar => 'baz' } };
    is_deeply $go->args, [];
};

subtest 'scalar dest on %foo (exception)' => sub {
    my $go = eval {
            create_obj(q|--foo "[qw/bar/]"|, {
            type => 'Eval',
            dest => \my %foo,
        });
    };
    my $error = quotemeta 'Option foo, key "[qw/bar/]", requires a value';
    like $go->error, qr/$error/;
};

subtest 'array dest on $foo' => sub {
    my $go = create_obj(q|--foo "{ bar => 'baz' }"|, {
        type => 'Array[Eval]',
        dest => \my $foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply $foo, [ { bar => 'baz' } ];
    is_deeply $go->args, [];
};

subtest 'array dest on $foo (defined)' => sub {
    my $foo = 'bar';
    my $go = create_obj(q|--foo "{ bar => 'baz' }"|, {
        type => 'Array[Eval]',
        dest => \$foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply $foo, [ { bar => 'baz' } ];
    is_deeply $go->args, [];
};

subtest 'array dest on @foo' => sub {
    my $go = create_obj(q|--foo "{ bar => 'baz' }"|, {
        type => 'Array[Eval]',
        dest => \my @foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \@foo, [ { bar => 'baz' } ];
    is_deeply $go->args, [];
};

subtest 'array dest on @foo (defined)' => sub {
    my @foo = qw(bar); 
    my $go = create_obj(q|--foo "{ bar => 'baz' }"|, {
        type => 'Array[Eval]',
        dest => \@foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \@foo, [ { bar => 'baz' } ];
    is_deeply $go->args, [];
};

subtest 'array dest on %foo' => sub {
    my $go = create_obj(q|--foo "a={ bar => 'baz' }"|, {
        type => 'Array[Eval]',
        dest => \my %foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \%foo, { a => { bar => 'baz' } };
    is_deeply $go->args, [];
};

subtest 'array dest on %foo (defined)' => sub {
    my %foo = (bar => 'baz');
    my $go = create_obj(q|--foo "a={ bar => 'baz' }"|, {
        type => 'Array[Eval]',
        dest => \%foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \%foo, { a => { bar => 'baz' } };
    is_deeply $go->args, [];
};

subtest 'array dest on %foo (exception)' => sub {
    my $go = eval {
            create_obj(q|--foo "[qw/bar/]"|, {
            type => 'Array[Eval]',
            dest => \my %foo,
        });
    };
    my $error = quotemeta 'Option foo, key "[qw/bar/]", requires a value';
    like $go->error, qr/$error/;
};

subtest 'hash dest on $foo' => sub {
    my $go = create_obj(q|--foo "a=[qw/bar/]"|, {
        type => 'Hash[Eval]',
        dest => \my $foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply $foo, { a => [qw/bar/] };
    is_deeply $go->args, [];
};

subtest 'hash dest on $foo (defined)' => sub {
    my $foo = 'bar';
    my $go = create_obj(q|--foo "a=[qw/bar/]"|, {
        type => 'Hash[Eval]',
        dest => \$foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply $foo, { a => [qw/bar/] };
    is_deeply $go->args, [];
};

subtest 'hash dest on @foo' => sub {
    my $go = create_obj(q|--foo "a=[qw/bar/]"|, {
        type => 'Hash[Eval]',
        dest => \my @foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \@foo, [ a => [qw/bar/] ];
    is_deeply $go->args, [];
};

subtest 'hash dest on @foo' => sub {
    my @foo = ('bar');
    my $go = create_obj(q|--foo "a=[qw/bar/]"|, {
        type => 'Hash[Eval]',
        dest => \@foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \@foo, [ a => [qw/bar/] ];
    is_deeply $go->args, [];
};

subtest 'hash dest on %foo' => sub {
    my $go = create_obj(q|--foo "a=[qw/bar/]"|, {
        type => 'Hash[Eval]',
        dest => \my %foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \%foo, { a => [qw/bar/] };
    is_deeply $go->args, [];
};

subtest 'hash dest on %foo (defined)' => sub {
    my %foo = (bar => 'baz');
    my $go = create_obj(q|--foo "a=[qw/bar/]"|, {
        type => 'Hash[Eval]',
        dest => \%foo,
    });
    is $go->opts->{foo}, undef;
    is_deeply \%foo, { a => [qw/bar/] };
    is_deeply $go->args, [];
};

subtest 'usage' => sub {
    like create_obj('', { type => 'Eval' })->usage, qr/Eval/;
    like create_obj('', { type => 'Array[Eval]' })->usage, qr/Array\[Eval\]/;
    like create_obj('', { type => 'Hash[Eval]' })->usage, qr/Hash\[Eval\]/;
};

done_testing;
