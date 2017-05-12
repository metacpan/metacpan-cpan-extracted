#!/usr/bin/perl -w

# test out signal emission hooks.

use strict;
use warnings;
use Test::More tests => 77;
use Glib ':constants';

Glib::Type->register_object (
    'Glib::Object',
    'Foo',
    signals => {
        wave => {},
        nod => {
            param_types => [qw(Glib::String Glib::Int)],
        },
        wink => {
            flags => ['run-last', 'detailed'],
            param_types => [qw(Glib::Boolean)],
            return_type => 'Glib::Boolean',
        },
        gesture => {
            flags => ['no-hooks'],
        },
    },
);
Glib::Type->register_object ('Foo', 'Bar');


my $foo = Glib::Object::new ('Foo');

isa_ok ($foo, 'Foo');
isa_ok ($foo, 'Glib::Object');

# add each emission hook a different way
my $wave_hook =
    $foo->signal_add_emission_hook (wave => \&generic_hook_data, {foo=>'bar'});
ok ($wave_hook, 'added hook for wave');
my $wink_hook =
    Foo->signal_add_emission_hook (wink => \&generic_hook_no_data);
ok ($wave_hook, 'added hook for wink');
my $nod_hook =
    Glib::Object::signal_add_emission_hook ('Foo', 'nod',
                                            'generic_hook_no_data');
ok ($wave_hook, 'added hook for nod');

{
    # This shouldn't work, as the signal is flagged as no-hooks.
    # It appears to generate a warning from GLib through g_log; let's
    # trap that.
    local $SIG{__WARN__} = sub { ok(1, "got warning text $_[0]"); };
    my $gesture_hook =
        Glib::Object::signal_add_emission_hook ('Foo', 'gesture',
                                                'generic_hook_data',
                                                {foo=>'bar'});
    ok (!$gesture_hook, 'can\'t add a hook for gesture');
}

# connect with detail; notify is the obvious choice, but it is defined
# as no-hooks, so that won't work.  let's just make something up.
my $detailed_hook =
    Foo->signal_add_emission_hook ('wink::sly', \&generic_hook_no_data);
ok ($detailed_hook, 'added hook for wink::sly');

# we can connect a hook to an inherited signal.  the hook will be invoked
# for emission of the signal from *any* class.
my $bar_wave_hook =
    Bar->signal_add_emission_hook (wave => \&generic_hook_no_data);
ok ($bar_wave_hook);


$foo->signal_connect ("wink" => sub { ok (1, "plain old wink")});
$foo->signal_connect ("wink::sly" => sub { ok (1, "wink::sly")});


# emit some signals...
# these variables communicate with generic_hook_no_data().
my $emission_count = 0;
my %emissions = ();
my $detail = undef;

# there are two hooks connected to this one.
print "\nemitting wave\n";
$foo->signal_emit ('wave');
is ($emissions{wave}, 2);

print "\nemitting nod\n";
$foo->signal_emit ('nod', "Whee!", 42);

print "\nemitting wink\n";
my $ret = $foo->signal_emit ('wink', TRUE);

$detail = 'sly';
print "\nemitting wink::$detail\n";
my $n_before = $emission_count;
$foo->signal_emit ("wink::$detail", FALSE);
is ($emission_count - $n_before, 2, 'detailed emission results in two hooks');

print "\nemitting gesture\n";
$n_before = $emission_count;
$foo->signal_emit ('gesture');
is ($emission_count, $n_before, 'no hook here');

print "\n";
is ($emission_count, 6, 'total emissions');
is ($emissions{'wave'}, 2, 'emissions for wave');
is ($emissions{'nod'}, 1, 'emissions for nod');
is ($emissions{'wink'}, 3, 'emissions for wink');
is ($emissions{'gesture'}, undef, 'emissions for gesture');


# remove all the hooks and emit again.
# the emission count should not change.
Foo->signal_remove_emission_hook (wave => $wave_hook);
Foo->signal_remove_emission_hook (wave => $bar_wave_hook);
Foo->signal_remove_emission_hook (nod => $nod_hook);
Foo->signal_remove_emission_hook (wink => $wink_hook);
Foo->signal_remove_emission_hook (wink => $detailed_hook);

$n_before = $emission_count;

$foo->signal_emit ('wave');
$foo->signal_emit ('nod', "Whee!", 42);
$ret = $foo->signal_emit ('wink', TRUE);
$foo->signal_emit ("wink::$detail", FALSE);
$foo->signal_emit ('gesture');

is ($emission_count, $n_before, 'no hooks here');


# test a self-removing hook.

Foo->signal_add_emission_hook (wave => sub {
    ok (1, 'got hooked');
    $emission_count++;
    FALSE
});

$n_before = $emission_count;
$foo->signal_emit ('wave');
$foo->signal_emit ('wave');
is ($emission_count - $n_before, 1, 'two emissions, one hook');



sub generic_hook_no_data {
    my ($ihint, $param_list) = @_;
    print "in hook for $ihint->{signal_name}  $ihint->{run_type}\n";
    $emission_count++;
    $emissions{$ihint->{signal_name}}++;
    use Data::Dumper;
    print Dumper([$ihint, $param_list]);
    isa_ok ($ihint, 'HASH');
    ok (exists $ihint->{signal_name}, 'ihint is valid');
    is ($ihint->{detail}, $detail, 'detail');
    isa_ok ($param_list, 'ARRAY');
    ok (@$param_list > 0, 'at least one thing in param_list');
    # GSignal doesn't care what the instance's type is, but we only
    # bind it to Glib::Object.
    isa_ok ($param_list->[0], 'Glib::Object');

    my $info = $param_list->[0]->signal_query ($ihint->{signal_name});
    ok (defined $info, 'found info about the signal');
    is (scalar(@$param_list), 1 + scalar(@{ $info->{param_types} }),
        'parameter count');
    return TRUE;
}

sub generic_hook_data {
    my ($ihint, $param_list, $user_data) = @_;

    isa_ok ($user_data, 'HASH');
    is ($user_data->{foo}, 'bar', 'user data is valid');

    # verify the invocation hint.
    my $other_hint = $param_list->[0]->signal_get_invocation_hint();
    is_deeply ($ihint, $other_hint);

    return generic_hook_no_data ($ihint, $param_list);
}

# vim: set et ts=4 sw=4 sts=4 syntax=perl :
