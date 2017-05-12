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

subtest 'Bool' => sub {
    my $go = create_obj('--foo bar', { type => 'Bool' });
    is $go->opts->{foo}, 1;
    is_deeply $go->args, ['bar'];
};

subtest 'Bool (default)' => sub {
    my $go = create_obj('bar', {
        type => 'Bool',
        opts => {
            default => 1,
        },
    });
    is $go->opts->{foo}, 1;
    is_deeply $go->args, ['bar'];
};

subtest 'Incr' => sub {
    my $go = create_obj('--foo bar --foo baz', { type => 'Incr' });
    is $go->opts->{foo}, 2;
    is_deeply $go->args, [qw/bar baz/];
};

subtest 'Str' => sub {
    my $go = create_obj('--foo bar baz', { type => 'Str' });
    is $go->opts->{foo}, 'bar';
    is_deeply $go->args, [qw/baz/];
};

subtest 'Int' => sub {
    my $go = create_obj('--foo 1 2 3', { type => 'Int' });
    is $go->opts->{foo}, 1;
    is_deeply $go->args, [qw/2 3/];
};

subtest 'Num' => sub {
    my $go = create_obj('--foo 0.12 0.23', { type => 'Num' });
    is $go->opts->{foo}, 0.12;
    is_deeply $go->args, [qw/0.23/];
};

subtest 'ExNum' => sub {
    my $go = create_obj('--foo 0xff 0777', { type => 'ExNum' });
    is $go->opts->{foo}, 0xff;
    is_deeply $go->args, [qw/0777/];
};

subtest 'Array[Str]' => sub {
    my $go = create_obj('--foo bar --foo baz hoge', { type => 'Array[Str]' });
    is_deeply $go->opts->{foo}, [qw/bar baz/];
    is_deeply $go->args, [qw/hoge/];
};

subtest 'Hash[Str]' => sub {
    my $go = create_obj('--foo "bar=baz" --foo "hoge=fuga" argv', { type => 'Hash[Str]' });
    is_deeply $go->opts->{foo}, { bar => 'baz', hoge => 'fuga' };
    is_deeply $go->args, [qw/argv/];
};

done_testing;
