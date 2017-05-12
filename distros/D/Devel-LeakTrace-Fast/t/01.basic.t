#!perl -w
use strict;
use Test::More tests => 11;

my $inc = join(' ', map { "-I$_" } @INC);

sub output ($) {
    my $code = shift;
    `$^X $inc -MDevel::LeakTrace::Fast -e'$code' 2>&1`
}

is( output '1;', '', 'no statements = no leak' );

is( output 'my $foo;', '', 'single scalar = no leak' );

local $_ = output q{
my $foo;
$foo = \$foo;
};

ok( $_, 'leak a reference loop $foo = \$foo' );
ok( s/^leaked SV\(.*?\) from -e line 3$//m, 'one SV');
ok( s/^leaked SV\(.*?\) from -e line 3$//m, 'another SV');
ok( m/^\n*$/,                               "and that's all" );

$_ = output q{
my @foo;
$foo[0] = \@foo;
};

ok( $_, 'leak a reference loop $foo[1] = \@foo' );
ok( s/^leaked SV\(.*?\) from -e line \d+$//m, 'one SV');
ok( s/^leaked AV\(.*?\) from -e line \d+$//m, 'one AV');
ok( s/^leaked RV\(.*?\) from -e line \d+$//m, 'one RV');
ok( m/^\n*$/,                               "and that's all" );
