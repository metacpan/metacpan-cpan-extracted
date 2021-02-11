use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Parse qw/valid_json parse_json/;
use JSON::Create qw/create_json create_json_strict/;

# # http://www.perlmonks.org/?node_id=703222

# Failed here:

# http://www.cpantesters.org/cpan/report/7405efdc-7a21-11e5-8b14-c5605feaeb47

# sub double_from_hex
# {
#     unpack 'd', scalar reverse pack 'H*', $_[0] 
# }

# use constant POS_INF => double_from_hex '7FF0000000000000';
# use constant NEG_INF => double_from_hex 'FFF0000000000000';

# use constant qNaN    => double_from_hex '7FF8000000000000';
# use constant NaN     => qNaN;

#my $nan = 'nan';
#my $nan = NaN;
# http://stackoverflow.com/questions/1185822/how-do-i-create-or-test-for-nan-or-infinity-in-perl

my $inf = 9**9**9;
my $neginf = -9**9**9;
my $nan = -sin(9**9**9);

# Seems to work on Perl 5.8:
# http://codepad.org/Dum7uLwD

#note "$inf $neginf $nan\n";

# The nan, inf, and -inf test the SVt_PVNV code path, because these
# are both a string and a number.

SKIP: {
    if (! $nan || ! $inf || ! $neginf) {
	skip 'Could not get nan or inf or neginf', 3*(
	    1   # tests with create_json
	    +2  # tests with create_json_strict
	    +2  # tests with object.
	);
    }

    my $bread = {
	#    'curry' => NaN,
	'curry' => $nan,
    };

    my $rice = {
	#    'rice' => POS_INF,
	'rice' => $inf,
    };

    my $lice = {
	#    'lice' => NEG_INF,
	'lice' => $neginf,
    };
    for my $thing ($bread, $rice, $lice) {

	# tests with create_json

	my $nanbread = create_json ($thing);
#	note ($nanbread);
	ok (valid_json ($nanbread), "non-finite is ok");

	# tests with create_json_strict

    {
	my $warning;
	local $SIG{__WARN__} = sub {$warning = "@_"};
	is (create_json_strict ($thing), undef,
	    "got undefined value with strict");
	like ($warning, qr/non-finite number/i,
	      "got warning with strict option");
    }
    }
    # tests with object.
    my $jcnfh = JSON::Create->new ();
    $jcnfh->non_finite_handler(sub {
	return 'null';
    });
    for my $thing ($bread, $rice, $lice) {
	my $jcout = $jcnfh->create ($thing);
	ok (valid_json ($jcout), "output using non-finite handler OK");
	like ($jcout, qr/{"(?:curry|rice|lice)":null\}/, "get null in output");
    }
};

my $floats = [1.0e-10, 0.1, 1.1, 9e9, 3.141592653,-1.0e-20,-9e19,];
for my $func (\&create_json, \&create_json_strict) {
    my $json = &{$func} ($floats);
    #note ($json);
    my $rt = parse_json ($json);
    is (ref $rt, 'ARRAY', "got array");
    cmp_ok (scalar (@$rt), '==', scalar (@$floats), "same number of members");
    for my $i (0..$#$rt) {
	my $diff = abs (($rt->[$i] - $floats->[$i])/($rt->[$i] + $floats->[$i]));
	cmp_ok ($diff, '<', 1/100_000.0, "value $i, $floats->[$i]");
	#    note ("$rt->[$i]  $floats->[$i] $diff");
    }
}
done_testing ();
