use warnings;
use strict;

use Carp;
use Data::Dumper;
use IPC::Shareable;
use Test::More;

# scalar ref

tie my $sv, 'IPC::Shareable', { destroy => 1 };

my $ref = 'ref';
$sv = \$ref;

is $$sv, $ref, "an SV can be assigned a reference to another scalar";

# array ref

$sv = [ 0 .. 9 ];
is ref($sv), 'ARRAY', "SV contains an aref ok";

for (0 .. 9) {
    is $sv->[$_], $_, "SV aref properly contains $_ at elem $_";
}

# hash ref

my %check;

my @k = map { ('a' .. 'z')[int(rand(26))] } (0 .. 9);
my @v = map { ('A' .. 'Z')[int(rand(26))] } (0 .. 9);
@check{@k} = @v;

$sv = { %check };
is ref($sv), 'HASH', "SV contains an href ok";

while (my($k, $v) = each %check){
    is $sv->{$k}, $v, "SV href key $k contains value $v ok";
}

# multiple refs

tie my @av, 'IPC::Shareable';

$av[0] = { foo => 'bar', baz => 'bash' };
$av[1] = [ 0 .. 9 ];

is ref($av[0]), 'HASH', "AV elem 0 is a hash";
is ref($av[1]), 'ARRAY', "AV elem 1 is an array";

is $av[0]->{foo}, 'bar', "AV->HV contains valid value in key 'foo'";
is $av[0]->{baz}, 'bash', "AV->HV contains valid value in key 'baz'";

for (0 .. 9) {
    is $av[1]->[$_], $_, "AV[1]->[$_] == $_ ok";
}

tie my %hv, 'IPC::Shareable';

for ('a' .. 'z') {
    $hv{lower}->{$_} = $_;
    $hv{upper}->{$_} = uc;
}

for ('a' .. 'z') {
    is $hv{lower}->{$_}, $_, "HV{lower}{$_} set to $_ ok";
    is $hv{upper}->{$_}, uc $_, "HV{upper}{$_} set to uppercase $_ ok";
}

IPC::Shareable->clean_up_all;

# deeply nested

tie $sv, 'IPC::Shareable', { destroy => 1 };

$sv->{this}->{is}->{nested}->{deeply}->[0]->[1]->[2] = 'found';


is
    $sv->{this}->{is}->{nested}->{deeply}->[0]->[1]->[2],
    'found',
    "crazy deep nested struct ok";

IPC::Shareable->clean_up_all;

done_testing();
