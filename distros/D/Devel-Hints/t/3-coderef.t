use strict;
use Config;
use Test::More;
BEGIN {
    if ($] < 5.010) {
        plan skip_all => "modifying coderef hints doesn't work properly on 5.8";
    }
    else {
        plan tests => 39;
    }
}
use ok 'Devel::Hints', ':all';
use Carp;


my ($sub, $line, $warning_bits, $open);
{
    package Foo;
    use warnings;
    no warnings 'deprecated';
    use open IO => ':utf8';
    BEGIN {
        $warning_bits = ${^WARNING_BITS};
        $open = ${^OPEN};
    }

    $[ = 10;
    $line = __LINE__ + 3;

    $sub = sub {
        warn 'foo';
        reset 'X';
        my @a = (1..10);
        /blarg/ || warn 'foo';
        if (sub { 1 }->()) {
            warn 'foo';
        }
        else {
            warn 'bar';
        }
        if (sub { 0 }->()) {
            warn 'bar';
        }
        else {
            warn 'foo';
        }
        for (1..3) {
            warn 'foo';
        }
        return (bless {}), $a[1], (warnings::enabled('redefine'));
    };
}

is(cop_label($sub), undef, 'cop_label');

is(cop_file($sub), __FILE__, 'cop_file');

is(cop_filegv($sub), \$::{'_<' . __FILE__}, 'cop_filegv');

is(cop_stashpv($sub), 'Foo', 'cop_stashpv');

{
    no strict 'refs';
    is_deeply(cop_stash($sub), \%{'Foo::'}, 'cop_stash');
}

ok(cop_seq($sub), 'cop_seq');

is(cop_arybase($sub), 10, 'cop_arybase');

is(cop_line($sub), $line, 'cop_line');

SKIP: {
    skip('cop_warnings() not available', 1) unless defined cop_warnings();

    is(cop_warnings($sub), $warning_bits, 'cop_warnings');
}

SKIP: {
    skip('cop_io() not available', 1) unless defined cop_io();

    is(cop_io($sub), $open, 'cop_io - empty string when not set');
}

my ($Topic, $TopicRV);
foreach (qw(label file filegv stashpv stash seq arybase line warnings io)) {
    no strict 'refs';

    $Topic = "cop_$_";
    $TopicRV = "cop_$_ - return value";
    &$_ if defined &$_;
}

sub label {
    ok(!eval { cop_label($sub => $Topic); 1 }, $Topic);
}

sub file {
    local $SIG{__WARN__} = sub { like($_[0], qr/$Topic/, $Topic) };
    is(cop_file($sub => $Topic), $Topic, $TopicRV);
    $sub->();
}

sub filegv {
    if ($] >= 5.010) { SKIP: { skip('cop_filegv not assignable in Perl 5.10+', 1); } return; }
    my $x = cop_filegv($sub, \*DATA);
    is($x, \*DATA, $TopicRV);
}

sub stashpv {
    local $SIG{__WARN__} = sub { };
    is(cop_stashpv($sub => $Topic), $Topic, $TopicRV);
    is(ref(($sub->())[0]), $Topic, $Topic);
}

sub stash {
    local $SIG{__WARN__} = sub { };
    $FOO::X = 1;
    is(cop_stash($sub => \%FOO::), \%FOO::, $TopicRV);
    $sub->();
    ok(!$FOO::X, $Topic);
}

sub seq {
    is(cop_seq($sub => 0), 0, $TopicRV);
}

sub arybase {
    local $SIG{__WARN__} = sub { };
    is(cop_arybase($sub => 1), 1, $TopicRV);
    is(($sub->())[1], 1, $Topic);
}

sub line {
    my $x = 0;
    my @lines = qw(1000 1003 1005 1014 1017 1017 1017);
    local $SIG{__WARN__} = sub { like($_[0], qr/$lines[$x++]/, $Topic) };
    is(cop_line($sub => 1000), 1000, $TopicRV);
    $sub->();
}

sub warnings {
    if ($] >= 5.010) { SKIP: { skip('cop_warnings not assignable in Perl 5.10+', 2); } return; }
    my $x;
    no warnings 'closure';
    no warnings 'redefine';
    BEGIN { $x = ${^WARNING_BITS} };
    is(cop_warnings($sub => ~$x), ~$x, $TopicRV);
    ok(($sub->())[2], $Topic);
}

sub io {
SKIP: {
    skip('cop_io() not available', 1) unless defined cop_io();
    is(cop_io($sub => ":raw\0:raw"), ":raw\0:raw", $TopicRV);
}
}
