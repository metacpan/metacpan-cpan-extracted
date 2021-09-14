# -*- perl -*-
# t/007-auxiliary.t
use 5.14.0;
use warnings;
use Carp;
use Devel::Git::MultiBisect::Auxiliary qw(
    clean_outputfile
    hexdigest_one_file
    validate_list_sequence
    write_transitions_report
);
use Test::More tests => 61;
use Cwd;
use File::Copy;
use File::Spec;
use File::Temp qw(tempdir);
use List::Util qw( sum );

my $cwd = cwd();
my $datadir = File::Spec->catfile($cwd, qw| t lib | );

##### clean_outputfile() #####

{
    my ($f1, $f2) = map { "output${_}.txt" } (1..2);
    my ($in1, $in2) = map { File::Spec->catfile($datadir, $_) } ($f1, $f2);
    my (@sizes_before, @digests_before);
    for ($in1, $in2) {
        push @sizes_before, (stat($_))[7];
        push @digests_before, hexdigest_one_file($_);
    }
    cmp_ok($sizes_before[0], '==', $sizes_before[1],
        "Before treatment, the two files have the same size");
    cmp_ok($digests_before[0], 'ne', $digests_before[1],
        "Before treatment, the two files have different md5_hex values");

    my $tdir1 = tempdir( CLEANUP => 1 );
    my $tdir2 = tempdir( CLEANUP => 1 );
    my $x1 = File::Spec->catfile($tdir1, $f1);
    my $x2 = File::Spec->catfile($tdir2, $f2);
    copy($in1 => $x1) or croak "Unable to copy $in1";
    copy($in2 => $x2) or croak "Unable to copy $in2";
    my $out1 = clean_outputfile($x1);
    my $out2 = clean_outputfile($x2);
    my (@sizes_after, @digests_after);
    for ($out1, $out2) {
        push @sizes_after, (stat($_))[7];
        push @digests_after, hexdigest_one_file($_);
    }
    cmp_ok($sizes_after[0], '==', $sizes_after[1],
        "After treatment, the two files have the same size");
    cmp_ok($digests_after[0], 'eq', $digests_after[1],
        "After treatment, the two files have the same md5_hex value");
}


##### hexdigest_one_file() #####

sub hex_tempfile {
    my ($string, $count, $extra) = @_;
    my $fh = File::Temp->new( UNLINK => 1, SUFFIX => '' );
    binmode $fh, ':raw';
    for (1..$count) { say $fh $string }
    say $fh $extra if $extra;
    close $fh or croak "Unable to close $fh after writing";
    return hexdigest_one_file($fh);
}

{
    my $basic       = 'x' x 10**2;
    my $minus       = 'x' x (10**2 - 1);
    my $end_a       = 'x' x (10**2 - 1) . 'a';
    my $end_b       = 'x' x (10**2 - 1) . 'b';
    my $plus        = 'x' x 10**2 . 'y';

    my @digests = (
        hex_tempfile($basic, 100, ''),
        hex_tempfile($basic, 100, ''),
        hex_tempfile($basic,  99, $minus),
        hex_tempfile($basic,  99, $end_a),
        hex_tempfile($basic,  99, $end_b),
        hex_tempfile($basic,  99, $plus),
    );

    cmp_ok($digests[0], 'eq', $digests[1],
        "Same md5_hex for identically written files");

    my %digests;
    $digests{$_}++ for @digests;

    my $expect = {
        $digests[0] => 2,
        $digests[2] => 1,
        $digests[3] => 1,
        $digests[4] => 1,
        $digests[5] => 1,
    };
    is_deeply(\%digests, $expect,
        "Got expected count of different digests");
}

##### validate_list_sequence #####

{
    my $rv;
    {
        my %hash = (
            'alpha' => 5,
            'beta'  => 2,
        );
        local $@;
        eval { $rv = validate_list_sequence(\%hash); };
        like($@, qr/\QMust provide array ref to validate_list_sequence()\E/,
            "Got expected error message for non-array-ref argument to validate_list_sequence()");
    }

    my @good_alpha = (
        ('alpha') x 5,
        (undef) x 5,
        ('alpha') x 5,
    );
    my @good_beta = (
        'beta',
    );
    my @good_gamma = (
        ('gamma') x 5,
        (undef) x 5,
        'gamma',
    );
    my @good_delta = (
        ('delta') x 5,
        undef,
        'delta',
        undef,
        'delta',
    );
    my @list_basic = (
        @good_alpha,
        @good_beta,
        @good_gamma,
        @good_delta,
    );

    note("List starts with undef");
    my @bad_1 = (undef, @list_basic);
    $rv = validate_list_sequence(\@bad_1);
    ok($rv, "validate_list_sequence() returned true value");
    is(ref($rv), 'ARRAY', "validate_list_sequence() returned array ref");
    is(scalar(@$rv), 3, "validate_list_sequence() returned array with 3 elements");
    is($rv->[0], 0, "list not validated");
    is($rv->[1], 0, "Failure to validate at index 0");
    is($rv->[2], 'first element undefined', "first element undefined");

    note("List ends with undef");
    my @bad_2 = (@list_basic, undef);
    $rv = validate_list_sequence(\@bad_2);
    ok($rv, "validate_list_sequence() returned true value");
    is(ref($rv), 'ARRAY', "validate_list_sequence() returned array ref");
    is(scalar(@$rv), 3, "validate_list_sequence() returned array with 3 elements");
    is($rv->[0], 0, "list not validated");
    is($rv->[1], $#bad_2, "Failure to validate at index $#bad_2");
    is($rv->[2], 'last element undefined', "last element undefined");

    note("List ends with previously seen value");
    my @bad_3 = (@list_basic, 'beta');
    $rv = validate_list_sequence(\@bad_3);
    ok($rv, "validate_list_sequence() returned true value");
    is(ref($rv), 'ARRAY', "validate_list_sequence() returned array ref");
    is(scalar(@$rv), 3, "validate_list_sequence() returned array with 3 elements");
    is($rv->[0], 0, "list not validated");
    is($rv->[1], $#bad_3, "Failure to validate at index $#bad_3");
    is($rv->[2], "$bad_3[-1] previously observed", "element $bad_3[-1] previously observed");

    note("List ends with undef, then previously seen value");
    my @bad_4 = (@list_basic, undef, 'beta');
    $rv = validate_list_sequence(\@bad_4);
    ok($rv, "validate_list_sequence() returned true value");
    is(ref($rv), 'ARRAY', "validate_list_sequence() returned array ref");
    is(scalar(@$rv), 3, "validate_list_sequence() returned array with 3 elements");
    is($rv->[0], 0, "list not validated");
    is($rv->[1], $#bad_4, "Failure to validate at index $#bad_4");
    is($rv->[2], "$bad_4[-1] previously observed", "element $bad_4[-1] previously observed");

    note("Sequence not closed off, ends with undef");
    my @bad_5 = (
        @good_alpha,
        @good_beta,
        undef,
        @good_gamma,
        @good_delta,
    );
    $rv = validate_list_sequence(\@bad_5);
    ok($rv, "validate_list_sequence() returned true value");
    is(ref($rv), 'ARRAY', "validate_list_sequence() returned array ref");
    is(scalar(@$rv), 3,
        "validate_list_sequence() returned array with 3 elements");
    is($rv->[0], 0, "list not validated");
    my $exp = scalar(@good_alpha) + scalar(@good_beta) + 1;
    is($rv->[1], $exp, "Failure to validate at index $exp");
    $exp -= 1;
    like($rv->[2],
        qr/\QImmediately preceding element (index $exp) not defined\E/,
        "Got expected error message"
    );

    #####


    note("Good list");
    $rv = validate_list_sequence(\@list_basic);
    ok($rv, "validate_list_sequence() returned true value");
    is(ref($rv), 'ARRAY', "validate_list_sequence() returned array ref");
    is(scalar(@$rv), 1, "validate_list_sequence() returned array with 1 element");
    ok($rv->[0], "validate_list_sequence() has true status");

    note("Problematic list");
    my $observed = [
        "318ce8b2ccb3e92a6e516e18d1481066",
        undef,
        undef,
        "318ce8b2ccb3e92a6e516e18d1481066",
        "318ce8b2ccb3e92a6e516e18d1481066",
        "e5a839ea2e34b8976000c78c258299b0",
        "e5a839ea2e34b8976000c78c258299b0",
        "e5a839ea2e34b8976000c78c258299b0",
        "f4920ddfdd9f1e6fc21ebfab09b5fcfe",
        "f4920ddfdd9f1e6fc21ebfab09b5fcfe",
        "f4920ddfdd9f1e6fc21ebfab09b5fcfe",
        "f4920ddfdd9f1e6fc21ebfab09b5fcfe",
        "d7125615b2e5dbb4750ff107bbc1bad3",
        "d7125615b2e5dbb4750ff107bbc1bad3",
    ];

    $rv = validate_list_sequence($observed);
    ok($rv, "validate_list_sequence() returned true value");
    is(ref($rv), 'ARRAY', "validate_list_sequence() returned array ref");
    is(scalar(@$rv), 1, "validate_list_sequence() returned array with 1 element");
    ok($rv->[0], "validate_list_sequence() has true status");

    #####

    note("Another problematic list");
    my @values = (
        "09431b9e74d329ef9ae0940eb0d279fb",
        "01ec704681e4680f683eaaaa6f83f79c",
        "b29d11b703576a350d91e1506674fd80",
        "481032a28823c8409a610e058b34a047",
    );
    my @counts = ( 55, 4, 6, 155 );
    $observed = [
        (("$values[0]") x $counts[0]),
        (("$values[1]") x $counts[1]),
        (("$values[2]") x $counts[2]),
        (("$values[0]") x $counts[3]),
    ];
    $rv = validate_list_sequence($observed);
    my $expfail = sum(@counts[0..2]);
    ok($rv, "validate_list_sequence() returned true value");
    is(ref($rv), 'ARRAY', "validate_list_sequence() returned array ref");
    is(scalar(@$rv), 3, "validate_list_sequence() returned array with 3 elements");
    is($rv->[0], 0, "list not validated");
    is($rv->[1], $expfail, "Failure to validate at index $expfail");
    is($rv->[2], "$values[0] previously observed", "element $values[0] previously observed");

    #####

    note("List with only one non-undef value seen");
    @counts = ( 1, 109, 1, 108, 1 );
    $observed = [
        (("$values[0]") x $counts[0]),
        ((undef) x $counts[1]),
        (("$values[0]") x $counts[2]),
        ((undef) x $counts[3]),
        (("$values[0]") x $counts[4]),
    ];
    $rv = validate_list_sequence($observed);
    ok($rv, "validate_list_sequence() returned true value");
    is(ref($rv), 'ARRAY', "validate_list_sequence() returned array ref");
    is(scalar(@$rv), 1, "validate_list_sequence() returned array with 1 element");
    ok($rv->[0], "validate_list_sequence() has true status");
}

##### write_transitions_report #####

{
    my $outputdir = tempdir( CLEANUP => 1 );
    my $report_basename = 'transitions.pl';

    {
        local $@;
        eval { write_transitions_report($outputdir, $report_basename); };
        like($@, qr/\QMust supply 3 arguments to write_transitions_report()\E/,
            "Got exception for insufficient number of arguments to write_transitions_report()");
    }
    {
        local $@;
        my $bad_arg = [];
        eval { write_transitions_report($outputdir, $report_basename, $bad_arg); };
        like($@, qr/\Q3rd argument to write_transitions_report() must be hashref\E/,
            "Got exception for non-hashref as 3rd argument to write_transitions_report()");
    }
    {
        local $@;
        my $bad_arg = { newest => 'foo', oldest => 'bar' };
        eval { write_transitions_report($outputdir, $report_basename, $bad_arg); };
        like($@, qr/\QMust be 3 elements in 3rd argument to write_transitions_report()\E/,
            "Got exception for insufficient number of elements in 3rd argument to write_transitions_report()");
    }
    {
        local $@;
        my $bad_arg = { newest => 'foo', oldest => 'bar', baz => 1 };
        my $missing = 'transitions';
        eval { write_transitions_report($outputdir, $report_basename, $bad_arg); };
        like($@, qr/\Q'$missing' element missing from 3rd argument to write_transitions_report()\E/,
            "Got exception for missing element '$missing' in 3rd argument to write_transitions_report()");
    }

    $outputdir = tempdir();  # Set CLEANUP => 1 when we're sure it's working
    my $expected_path = File::Spec->catdir($outputdir, $report_basename);
    my $transitions_data = {
      newest => {
        file => "/tmp/uLAXJKytVu/cab7765.make.stderr.txt",
        idx => 308,
        md5_hex => "b9723c289e0d60084f639c8ed3c9a846",
      },
      oldest => {
        file => "/tmp/uLAXJKytVu/7631dcc.make.stderr.txt",
        idx => 0,
        md5_hex => "54fc3796601f695b047d9fbcbc309d74",
      },
      transitions => [
        {
          newer => {
                     file => "/tmp/uLAXJKytVu/6e7a781.make.stderr.txt",
                     idx => 1,
                     md5_hex => "42dcaf235c5d2ac2a555896ca43e0ba8",
                   },
          older => {
                     file => "/tmp/uLAXJKytVu/7631dcc.make.stderr.txt",
                     idx => 0,
                     md5_hex => "54fc3796601f695b047d9fbcbc309d74",
                   },
        },
        {
          newer => {
                     file => "/tmp/uLAXJKytVu/48d2135.make.stderr.txt",
                     idx => 283,
                     md5_hex => "b9723c289e0d60084f639c8ed3c9a846",
                   },
          older => {
                     file => "/tmp/uLAXJKytVu/7073dfe.make.stderr.txt",
                     idx => 282,
                     md5_hex => "42dcaf235c5d2ac2a555896ca43e0ba8",
                   },
        },
      ],
    };
    my $transitions_report = write_transitions_report($outputdir, $report_basename, $transitions_data);
    ok(-f $transitions_report, "Wrote $transitions_report");
    ok(-s $transitions_report, "$transitions_report has content");
}
