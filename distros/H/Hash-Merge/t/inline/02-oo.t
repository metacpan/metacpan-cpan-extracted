use Test::More;

BEGIN
{
    $ENV{CLONE_CHOOSE_PREFERRED_BACKEND}
      and eval "use $ENV{CLONE_CHOOSE_PREFERRED_BACKEND}; 1;";
    $@ and plan skip_all => "No $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} found.";
}

use Hash::Merge;

my %left = (
    ss => 'left',
    sa => 'left',
    sh => 'left',
    so => 'left',
    as => ['l1', 'l2'],
    aa => ['l1', 'l2'],
    ah => ['l1', 'l2'],
    ao => ['l1', 'l2'],
    hs => {left => 1},
    ha => {left => 1},
    hh => {left => 1},
    ho => {left => 1},
    os => {foo => bless({key => 'left'}, __PACKAGE__)},
    oa => {foo => bless({key => 'left'}, __PACKAGE__)},
    oh => {foo => bless({key => 'left'}, __PACKAGE__)},
    oo => {foo => bless({key => 'left'}, __PACKAGE__)},
);

my %right = (
    ss => 'right',
    as => 'right',
    hs => 'right',
    os => 'right',
    sa => ['r1', 'r2'],
    aa => ['r1', 'r2'],
    ha => ['r1', 'r2'],
    oa => ['r1', 'r2'],
    sh => {right => 1},
    ah => {right => 1},
    hh => {right => 1},
    oh => {right => 1},
    so => {foo => bless({key => 'right'}, __PACKAGE__)},
    ao => {foo => bless({key => 'right'}, __PACKAGE__)},
    ho => {foo => bless({key => 'right'}, __PACKAGE__)},
    oo => {foo => bless({key => 'right'}, __PACKAGE__)},
);

# Test left precedence
my $merge = Hash::Merge->new();
ok($merge->get_behavior() eq 'LEFT_PRECEDENT', 'no arg default is LEFT_PRECEDENT');

my %lp = %{$merge->merge(\%left, \%right)};

is_deeply($lp{ss}, 'left', 'Left Precedent - Scalar on Scalar');
is_deeply($lp{sa}, 'left', 'Left Precedent - Scalar on Array');
is_deeply($lp{sh}, 'left', 'Left Precedent - Scalar on Hash');
is_deeply($lp{so}, 'left', 'Left Precedent - Scalar on Object');
is_deeply($lp{as}, ['l1', 'l2', 'right'], 'Left Precedent - Array on Scalar');
is_deeply($lp{aa}, ['l1', 'l2', 'r1', 'r2'], 'Left Precedent - Array on Array');
is_deeply($lp{ah}, ['l1', 'l2', 1], 'Left Precedent - Array on Hash');
is_deeply($lp{ao}, ['l1', 'l2', {key => 'right'}], 'Left Precedent - Array on Object');
is_deeply($lp{hs}, {left => 1}, 'Left Precedent - Hash on Scalar');
is_deeply($lp{ha}, {left => 1}, 'Left Precedent - Hash on Array');
is_deeply(
    $lp{hh},
    {
        left  => 1,
        right => 1,
    },
    'Left Precedent - Hash on Hash'
);
is_deeply(
    $lp{ho},
    {
        left => 1,
        foo  => {
            key => 'right',
        },
    },
    'Left Precedent - Hash on Object'
);
is_deeply($lp{os}, {foo => {key => 'left'}}, 'Left Precedent - Object on Scalar');
is_deeply($lp{oa}, {foo => {key => 'left'}}, 'Left Precedent - Object on Array');
is_deeply(
    $lp{oh},
    {
        foo   => {key => 'left'},
        right => 1,
    },
    'Left Precedent - Object on Array'
);
is_deeply($lp{oo}, {foo => {key => 'left'}}, 'Left Precedent - Object on Array');

ok($merge->set_behavior('RIGHT_PRECEDENT') eq 'LEFT_PRECEDENT', 'set_behavior() returns previous behavior');
ok($merge->get_behavior() eq 'RIGHT_PRECEDENT',                 'set_behavior() actually sets the behavior)');

my %rp = %{$merge->merge(\%left, \%right)};

is_deeply($rp{ss}, 'right', 'Right Precedent - Scalar on Scalar');
is_deeply($rp{sa}, ['left', 'r1', 'r2'], 'Right Precedent - Scalar on Array');
is_deeply($rp{sh}, {right => 1}, 'Right Precedent - Scalar on Hash');
is_deeply($rp{so}, {foo => {key => 'right'}}, 'Right Precedent - Scalar on Object');
is_deeply($rp{as}, 'right', 'Right Precedent - Array on Scalar');
is_deeply($rp{aa}, ['l1', 'l2', 'r1', 'r2'], 'Right Precedent - Array on Array');
is_deeply($rp{ah}, {right => 1}, 'Right Precedent - Array on Hash');
is_deeply($rp{ao}, {foo => {key => 'right'}}, 'Right Precedent - Array on Object');
is_deeply($rp{hs}, 'right', 'Right Precedent - Hash on Scalar');
is_deeply($rp{ha}, [1, 'r1', 'r2'], 'Right Precedent - Hash on Array');
is_deeply(
    $rp{hh},
    {
        left  => 1,
        right => 1,
    },
    'Right Precedent - Hash on Hash'
);
is_deeply(
    $rp{ho},
    {
        foo  => {key => 'right'},
        left => 1,
    },
    'Right Precedent - Hash on Object'
);
is_deeply($rp{os}, 'right', 'Right Precedent - Object on Scalar');
is_deeply($rp{oa}, [{key => 'left'}, 'r1', 'r2'], 'Right Precedent - Object on Array');
is_deeply(
    $rp{oh},
    {
        foo   => {key => 'left'},
        right => 1,
    },
    'Right Precedent - Object on Hash'
);
is_deeply($rp{oo}, {foo => {key => 'right'}}, 'Right Precedent - Object on Object');

Hash::Merge::set_behavior('STORAGE_PRECEDENT');
ok($merge->get_behavior() eq 'RIGHT_PRECEDENT', '"global" function does not affect object');
$merge->set_behavior('STORAGE_PRECEDENT');

my %sp = %{$merge->merge(\%left, \%right)};

is_deeply($sp{ss}, 'left', 'Storage Precedent - Scalar on Scalar');
is_deeply($sp{sa}, ['left', 'r1', 'r2'], 'Storage Precedent - Scalar on Array');
is_deeply($sp{sh}, {right => 1}, 'Storage Precedent - Scalar on Hash');
is_deeply($sp{so}, {foo => {key => 'right'}}, 'Storage Precedent - Scalar on Object');
is_deeply($sp{as}, ['l1', 'l2', 'right'], 'Storage Precedent - Array on Scalar');
is_deeply($sp{aa}, ['l1', 'l2', 'r1', 'r2'], 'Storage Precedent - Array on Array');
is_deeply($sp{ah}, {right => 1}, 'Storage Precedent - Array on Hash');
is_deeply($sp{ao}, {foo => {key => 'right'}}, 'Storage Precedent - Array on Object');
is_deeply($sp{hs}, {left => 1}, 'Storage Precedent - Hash on Scalar');
is_deeply($sp{ha}, {left => 1}, 'Storage Precedent - Hash on Array');
is_deeply(
    $sp{hh},
    {
        left  => 1,
        right => 1,
    },
    'Storage Precedent - Hash on Hash'
);
is_deeply(
    $sp{ho},
    {
        foo  => {key => 'right'},
        left => 1,
    },
    'Storage Precedent - Hash on Object'
);
is_deeply($sp{os}, {foo => {key => 'left'}}, 'Storage Precedent - Object on Scalar');
is_deeply($sp{oa}, {foo => {key => 'left'}}, 'Storage Precedent - Object on Array');
is_deeply(
    $sp{oh},
    {
        foo   => {key => 'left'},
        right => 1,
    },
    'Storage Precedent - Object on Hash'
);
is_deeply($sp{oo}, {foo => {key => 'left'}}, 'Storage Precedent - Object on Object');

$merge->set_behavior('RETAINMENT_PRECEDENT');
my %rep = %{$merge->merge(\%left, \%right)};

is_deeply($rep{ss}, ['left', 'right'], 'Retainment Precedent - Scalar on Scalar');
is_deeply($rep{sa}, ['left', 'r1', 'r2'], 'Retainment Precedent - Scalar on Array');
is_deeply(
    $rep{sh},
    {
        left  => 'left',
        right => 1,
    },
    'Retainment Precedent - Scalar on Hash'
);
is_deeply(
    $rep{so},
    {
        foo  => {key => 'right'},
        left => 'left',
    },
    'Retainment Precedent - Scalar on Object'
);
is_deeply($rep{as}, ['l1', 'l2', 'right'], 'Retainment Precedent - Array on Scalar');
is_deeply($rep{aa}, ['l1', 'l2', 'r1', 'r2'], 'Retainment Precedent - Array on Array');
is_deeply(
    $rep{ah},
    {
        l1    => 'l1',
        l2    => 'l2',
        right => 1,
    },
    'Retainment Precedent - Array on Hash'
);
is_deeply(
    $rep{ao},
    {
        foo => {key => 'right'},
        l1  => 'l1',
        l2  => 'l2',
    },
    'Retainment Precedent - Array on Object'
);
is_deeply(
    $rep{hs},
    {
        left  => 1,
        right => 'right',
    },
    'Retainment Precedent - Hash on Scalar'
);
is_deeply(
    $rep{ha},
    {
        left => 1,
        r1   => 'r1',
        r2   => 'r2',
    },
    'Retainment Precedent - Hash on Array'
);
is_deeply(
    $rep{hh},
    {
        left  => 1,
        right => 1,
    },
    'Retainment Precedent - Hash on Hash'
);
is_deeply(
    $rep{ho},
    {
        foo  => {key => 'right'},
        left => 1,
    },
    'Retainment Precedent - Hash on Object'
);
is_deeply(
    $rep{os},
    {
        foo   => {key => 'left'},
        right => 'right',
    },
    'Retainment Precedent - Object on Scalar'
);
is_deeply(
    $rep{oa},
    {
        foo => {key => 'left'},
        r1  => 'r1',
        r2  => 'r2',
    },
    'Retainment Precedent - Object on Array'
);
is_deeply(
    $rep{oh},
    {
        foo   => {key => 'left'},
        right => 1,
    },
    'Retainment Precedent - Object on Hash'
);
is_deeply($rep{oo}, {foo => [{key => 'left'}, {key => 'right'},]}, 'Retainment Precedent - Object on Object');

$merge->add_behavior_spec(
    {
        SCALAR => {
            SCALAR => sub { $_[0] },
            ARRAY  => sub { $_[0] },
            HASH   => sub { $_[0] }
        },
        ARRAY => {
            SCALAR => sub { $_[0] },
            ARRAY  => sub { $_[0] },
            HASH   => sub { $_[0] }
        },
        HASH => {
            SCALAR => sub { $_[0] },
            ARRAY  => sub { $_[0] },
            HASH   => sub { $_[0] }
        }
    },
    "My Behavior"
);

SCOPE: {
    my $err;
    local $SIG{__WARN__} = sub { $err = shift };
    eval { $merge->specify_behavior( $merge->get_behavior_spec("My Behavior"), "My Behavior" ) };
    $@ and $err = $@;
    like($err, qr/already defined. Please take another name/, "Cannot add behavior spec twice");
}

my %cp = %{$merge->merge(\%left, \%right)};

is_deeply($cp{ss}, 'left', 'Custom Precedent - Scalar on Scalar');
is_deeply($cp{sa}, 'left', 'Custom Precedent - Scalar on Array');
is_deeply($cp{sh}, 'left', 'Custom Precedent - Scalar on Hash');
is_deeply($cp{so}, 'left', 'Custom Precedent - Scalar on Object');
is_deeply($cp{as}, ['l1', 'l2'], 'Custom Precedent - Array on Scalar');
is_deeply($cp{aa}, ['l1', 'l2'], 'Custom Precedent - Array on Array');
is_deeply($cp{ah}, ['l1', 'l2'], 'Custom Precedent - Array on Hash');
is_deeply($cp{ao}, ['l1', 'l2'], 'Custom Precedent - Array on Object');
is_deeply($cp{hs}, {left => 1}, 'Custom Precedent - Hash on Scalar');
is_deeply($cp{ha}, {left => 1}, 'Custom Precedent - Hash on Array');
is_deeply($cp{hh}, {left => 1}, 'Custom Precedent - Hash on Hash');
is_deeply($cp{ho}, {left => 1}, 'Custom Precedent - Hash on Hash');
is_deeply($cp{os}, {foo => {key => 'left'}}, 'Custom Precedent - Object on Scalar');
is_deeply($cp{oa}, {foo => {key => 'left'}}, 'Custom Precedent - Object on Array');
is_deeply($cp{oh}, {foo => {key => 'left'}}, 'Custom Precedent - Object on Hash');
is_deeply($cp{oo}, {foo => {key => 'left'}}, 'Custom Precedent - Object on Object');

{
    package    # Test sponsored by David Wheeler
      HashMergeHashContainer;
    my $h1 = {
        foo => bless {one => 2},
        __PACKAGE__
    };
    my $h2 = {
        foo => bless {one => 2},
        __PACKAGE__
    };
    my $merged = Hash::Merge->new->merge($h1, $h2);
    main::ok($merged);
}

{
    my $destroyed = 0;
    no warnings 'once';
    local *Hash::Merge::DESTROY = sub { $destroyed = 1 };
    use warnings;
    Hash::Merge->new;
    ok $destroyed, "instance did not leak";
}

done_testing;
