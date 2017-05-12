use strict;
use warnings;
use Test::More tests => 70;
use lib '../lib';
use Hash::Abbrev;

sub t {
    my ($name, $test) = @_;
    my @tests = qw(is); #qw(ok is isnt like cmp_ok);
    no strict 'refs';
    no warnings 'redefine';
    my ($sub, $count);
    next_test:
        $sub = shift @tests;
        local *$sub = do {
            my $code = \&{$Test::More::{$sub}};
            sub {$code->(@_, $name.' '.++$count)}
        };
    goto next_test if @tests;
    local $Test::Builder::Level
        = $Test::Builder::Level + 1;
    $test->()
}

my $hash = abbrev qw(list edit send);

t 'initial' => sub {
    is \$$hash{$_}, \$$hash{list} for qw (l li lis);
    is \$$hash{$_}, \$$hash{edit} for qw (e ed edi);
    is \$$hash{$_}, \$$hash{send} for qw (s se sen);
};


t 'update alias' => sub {
    $_ .= '!' for @$hash{qw/li ed se/};

    is $$hash{$_}, 'list!' for qw (l li lis list);
    is $$hash{$_}, 'edit!' for qw (e ed edi edit);
    is $$hash{$_}, 'send!' for qw (s se sen send);
};


t 'replace' => sub {
    @$hash{qw/l e s/} = (1, 2, 3);

    is $$hash{$_}, 1 for qw (l li lis list);
    is $$hash{$_}, 2 for qw (e ed edi edit);
    is $$hash{$_}, 3 for qw (s se sen send);
};

t 'update replacement' => sub {
    $$hash{$_} += 10 for qw(list edit send);

    is $$hash{$_}, 11 for qw (l li lis list);
    is $$hash{$_}, 12 for qw (e ed edi edit);
    is $$hash{$_}, 13 for qw (s se sen send);
};

t 'dispatch table' => sub {
    my $tab = abbrev qw(one two three);
    $$tab{one}   = sub {"one(@_)"};
    $$tab{two}   = sub {"two(@_)"};
    $$tab{three} = sub {"three(@_)"};

    is $$tab{$_}(1), 'one(1)'   for qw (o on one);
    is $$tab{$_}(2), 'two(2)'   for qw (tw two);
    is $$tab{$_}(3), 'three(3)' for qw (th thr thre three);
};

t 'existing' => sub {
    my $hash = abbrev my $pre = {
        one => sub {"one(@_)"},
        two => sub {"two(@_)"},
    };

    is $$hash{$_}(1), 'one(1)' for qw (o on one);
    is $$hash{$_}(2), 'two(2)' for qw (t tw two);
    is $pre, $hash;
};

t 'existing in place', sub {
    my %hash = (
        file      => sub {"file(@_)"},
        directory => sub {"directory(@_)"},
    );

    abbrev \%hash;

    is $hash{f}('abc.txt'), 'file(abc.txt)';
    is $hash{dir}('/'),     'directory(/)';

    $hash{fi} = sub {"elif(@_)"};

    is $hash{file}('abc'), 'elif(abc)';

    $hash{directory} = sub {"dir(@_)"};

    is $hash{d}('xyz'), 'dir(xyz)';
};

t 'existing in place + more', sub {
    my %hash = (
        file      => sub {"file(@_)"},
        directory => sub {"directory(@_)"},
    );

    abbrev \%hash, 'save';

    $hash{s} = sub {"save(@_)"};

    is $hash{save}(),       'save()';
    is $hash{fi}('abc.txt'),'file(abc.txt)';
    is $hash{di}('/'),      'directory(/)';

    $hash{f} = sub {"elif(@_)"};

    is $hash{file}('abc'), 'elif(abc)';

    $hash{directory} = sub {"dir(@_)"};

    is $hash{d}('xyz'), 'dir(xyz)';
}
