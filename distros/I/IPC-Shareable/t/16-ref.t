use warnings;
use strict;

use Carp;
use Data::Dumper;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);


# serializer: storable
{
    # scalar ref
    tie my $sv, 'IPC::Shareable', { destroy => 1 , serializer => 'storable' };

    my $ref = 'ref';
    $sv = \$ref;

    is $$sv, $ref, "storable: SV can be assigned a reference to another scalar";

    # array ref

    $sv = [ 0 .. 9 ];
    is ref($sv), 'ARRAY', "storable: SV contains an aref ok";

    for (0 .. 9) {
        is $sv->[$_], $_, "storable: SV aref elem $_ ok";
    }

    # hash ref

    my %check;

    my @k = map { ('a' .. 'z')[int(rand(26))] } (0 .. 9);
    my @v = map { ('A' .. 'Z')[int(rand(26))] } (0 .. 9);
    @check{@k} = @v;

    $sv = { %check };
    is ref($sv), 'HASH', "storable: SV contains an href ok";

    while (my($k, $v) = each %check) {
        is $sv->{$k}, $v, "storable: SV href key $k contains value $v ok";
    }

    # multiple refs

    tie my @av, 'IPC::Shareable';

    $av[0] = { foo => 'bar', baz => 'bash' , serializer => 'storable' };
    $av[1] = [ 0 .. 9 ];

    is ref($av[0]), 'HASH',  "storable: AV elem 0 is a hash";
    is ref($av[1]), 'ARRAY', "storable: AV elem 1 is an array";

    is $av[0]->{foo}, 'bar',  "storable: AV->HV contains valid value in key 'foo'";
    is $av[0]->{baz}, 'bash', "storable: AV->HV contains valid value in key 'baz'";

    for (0 .. 9) {
        is $av[1]->[$_], $_, "storable: AV[1]->[$_] == $_ ok";
    }

    tie my %hv, 'IPC::Shareable', { serializer => 'storable' };

    for ('a' .. 'z') {
        $hv{lower}->{$_} = $_;
        $hv{upper}->{$_} = uc;
    }

    for ('a' .. 'z') {
        is $hv{lower}->{$_}, $_, "storable: HV{lower}{$_} set to $_ ok";
        is $hv{upper}->{$_}, uc $_, "storable: HV{upper}{$_} set to uppercase $_ ok";
    }

    IPC::Shareable->clean_up_all;

    # deeply nested

    tie $sv, 'IPC::Shareable', { serializer => 'storable', destroy => 1 };

    $sv->{this}->{is}->{nested}->{deeply}->[0]->[1]->[2] = 'found';

    is
        $sv->{this}->{is}->{nested}->{deeply}->[0]->[1]->[2],
        'found',
        "storable: crazy deep nested struct ok";

    IPC::Shareable->clean_up_all;
}

# serializer: json
{
    # scalar ref
    tie my $sv, 'IPC::Shareable', { serializer => 'json', destroy => 1 };

    my $ref = 'ref';
    $sv = \$ref;

    is $$sv, $ref, "json: SV can be assigned a reference to another scalar";

    # array ref

    $sv = [ 0 .. 9 ];
    is ref($sv), 'ARRAY', "json: SV contains an aref ok";

    for (0 .. 9) {
        is $sv->[$_], $_, "json: SV aref elem $_ ok";
    }

    # hash ref

    my %check;

    my @k = ('a' .. 'j');
    my @v = ('A' .. 'J');
    @check{@k} = @v;

    $sv = { %check };
    is ref($sv), 'HASH', "json: SV contains an href ok";

    for my $k (@k) {
        is $sv->{$k}, $check{$k}, "json: SV href key $k ok";
    }

    # multiple refs via array tie

    tie my @av, 'IPC::Shareable', { serializer => 'json', destroy => 1 };

    $av[0] = { foo => 'bar', baz => 'bash' };
    $av[1] = [ 0 .. 9 ];

    is ref($av[0]), 'HASH',  "json: AV elem 0 is a hash";
    is ref($av[1]), 'ARRAY', "json: AV elem 1 is an array";

    is $av[0]->{foo}, 'bar',  "json: AV->HV contains valid value in key 'foo'";
    is $av[0]->{baz}, 'bash', "json: AV->HV contains valid value in key 'baz'";

    for (0 .. 9) {
        is $av[1]->[$_], $_, "json: AV[1]->[$_] == $_ ok";
    }

    tie my %hv, 'IPC::Shareable', { serializer => 'json', destroy => 1 };

    for ('a' .. 'z') {
        $hv{lower}->{$_} = $_;
        $hv{upper}->{$_} = uc;
    }

    for ('a' .. 'z') {
        is $hv{lower}->{$_}, $_, "json: HV{lower}{$_} set to $_ ok";
        is $hv{upper}->{$_}, uc $_, "json: HV{upper}{$_} set to uppercase $_ ok";
    }

    IPC::Shareable->clean_up_all;

    # deeply nested via hash tie

    tie my %dh, 'IPC::Shareable', { serializer => 'json', destroy => 1 };

    $dh{this}{is}{nested}{deeply}[0][1][2] = 'found';

    is
        $dh{this}{is}{nested}{deeply}[0][1][2],
        'found',
        "json: crazy deep nested struct ok";

    IPC::Shareable->clean_up_all;

    # scalar child segment: json scalar-tie holding a ref to a pre-tied child scalar.
    # Exercises _encode_json_prepare SCALAR/REF branch (writes __ics__ marker) and
    # _decode_json TYPE_SCALAR + __ics__ branch (reattaches child on decode).
    # The "cold re-attach" sub-test verifies _decode_json_resolve/_decode_json_reattach
    # work correctly when there is no prior _data cache (new tie to the same key).

    {
        tie my $sv,    'IPC::Shareable', { key => unique_glue('16svp'), serializer => 'json', create => 1, destroy => 0 };
        tie my $child, 'IPC::Shareable', { key => unique_glue('16svc'), serializer => 'json', create => 1, destroy => 0 };

        $child = 'hello';
        $sv    = \$child;

        is ref($sv), 'SCALAR', "json: scalar-tie can hold a ref to a child scalar segment";
        is $$sv,     'hello',  "json: child scalar value readable through parent ref";

        $$sv = 'world';
        is $$sv, 'world', "json: child scalar writable through parent ref";

        # Cold re-attach: new tie to the same parent key, no prior _data cache.
        # _decode_json must reattach the child scalar segment from the __ics__ marker.
        tie my $sv2, 'IPC::Shareable', { key => unique_glue('16svp'), serializer => 'json', create => 0, destroy => 0 };
        is ref($sv2), 'SCALAR', "json: cold re-attach of scalar child: parent holds scalar ref";
        is $$sv2,     'world',  "json: cold re-attach of scalar child: correct value via re-attached child";

        IPC::Shareable->clean_up_all;
    }
}

IPC::Shareable::_end;

assert_clean_process();

done_testing();
