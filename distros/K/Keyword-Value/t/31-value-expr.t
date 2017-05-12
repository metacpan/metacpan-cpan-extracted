use v5.22;

use Test::More;
use Test::Deep;

use Keyword::Value;

value my $i     = 1;
value our $j    = [2];
value $::k      = { qw( a b ) };

cmp_deeply $i, 1,               '$i = 1'
or BAIL_OUT 'mis-assigned $i';

cmp_deeply $j, [2],             '$j = [2]'    
or BAIL_OUT 'mis-assigned $j';

cmp_deeply $::k, { qw( a b ) },   '$::k = { qw( a b ) }'
or BAIL_OUT 'mis-assigned $::k';

my $err_01  = qr/^Modification of a read-only value attempted/;
my $err_02  = qr/^Attempt to access disallowed key/;
my $err_03  = qr/^Attempt to delete readonly key/;
my $err_04  = qr/^Attempt to delete disallowed key/;

eval
{
    ++$i;
    fail 'increment $i';
    1
};
like $@, $err_01, 'increment $i';

eval
{
    $j->[0] = 3;
    fail 'assign $j->[0]';
    1
};
like $@, $err_01, 'assign $j->[0]';

eval
{
    $j->[1] = 4;
    fail 'assign $j->[1]';
    1
};
like $@, $err_01, 'assign $j->[1]';

eval
{
    push @$j, 3;
    fail 'push';
    1
};
like $@, $err_01, 'push';

eval
{
    pop @$j;
    fail 'pop';
    1
};
like $@, $err_01, 'pop';

eval
{
    ++$j->[0];
    fail 'increment $j->[0]';
    1
};
like $@, $err_01, 'increment $j->[0]';

eval
{
    ++$j->[0];
    fail 'assign $j->[0]';
    1
};
like $@, $err_01, 'assign $j->[0]';

eval
{
    delete $j->[0];
    fail 'delete $j->[0]';
    1
};
like $@, $err_01, 'delete $j->[0]';

eval
{
    ++$::k->{a};
    fail 'incremet $::k->{a}';
    1
};
like $@, $err_01, 'incremet $::k->{a}';

eval
{
    $::k->{a} = 'c';
    fail 'assign $::k->{a}';
    1
};
like $@, $err_01, 'assign $::k->{a}';

eval
{
    $::k->{z} = 'y';
    fail 'assign $::k->{z}';
    1
};
like $@, $err_02, 'assign $::k->{z}';

eval
{
    delete $::k->{a};
    fail 'delete $::k->{a}';
    1
};
like $@, $err_03, 'delete $::k->{a}';

eval
{
    delete $::k->{z};
    fail 'delete $::k->{z}';
    1
};
like $@, $err_04, 'delete $::k->{z}';

done_testing;
