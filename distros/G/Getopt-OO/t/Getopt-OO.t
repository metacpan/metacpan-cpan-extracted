# $Log: Getopt-OO.t,v $
# Revision 1.13  2005/02/05 17:19:31  sjs
# added tests for other_values changes.
#
# Revision 1.12  2005/02/04 02:56:21  sjs
# change the way we test for no Values from being == 0 to
# !Values().
#
# Revision 1.11  2005/02/03 03:42:05  sjs
# Added a test case to check for empty other_values with no
# required value.
#
# Revision 1.10  2005/01/31 04:05:50  sjs
# Fixed a warning on $m8 variable.
#
# Revision 1.9  2005/01/31 04:03:06  sjs
# Added and updated tests.
#
# Revision 1.8  2005/01/28 07:47:40  sjs
# modified other_values behaviour
#
# Revision 1.7  2005/01/23 22:18:34  sjs
# Fixed test 51.
#
# Revision 1.6  2005/01/23 20:38:23  sjs
# Mostly addition of test cases for new code.
# Print linenumbers for failed tests.
#
$| = 1;
use IO::File;
use strict;

BEGIN{
	eval {
		require 'Getopt/OO.pm';
	};
	die "1..1\n${@}not ok" if $@;
};

# Am using this instead of Test::More because this needs to be installed
# on some older versions of Perl that don''t have Test::More installed and
# I can''t install it.
{
	local *F;
	open F, $0;
	my $number_of_tests = (grep /^\s*OK\s*\(/, <F>);
	close F;
	my $number_completed = 0;
	my $number_passed = 0;
	print "1..$number_of_tests\n";

	sub OK{
		my ($test, $string) = @_;
		$number_completed++;
		my $line_number = (caller(0))[2];
		print(($test)
			? ''
			: "line $line_number:$string\nnot "
			, "ok $number_completed\n");
	}
}

	#########################

{
my $help = 'USAGE: Getopt-OO.t [-ab ]
    -a  help for a
    -b  help for b
';
	my $h;
	eval {
		$h = Getopt::OO->new(
			['-a'],
			'-a' => {help => 'help for a'},
			'-b' => {help => 'help for b'},
		);
	};
	OK(!$@,						"Crashed");
	OK(defined $h, 				"No handle returned");
	if (defined $h) {
		OK($h->isa('Getopt::OO'),	"Handle looks wrong.");
		OK($h->Help() eq $help, 	"Help looks wrong:" . $h->Help());
		OK(
			$h->Values() == 1, 
			"Values looks wrong for checking number of ars"
		);
		OK(
			$h->Values('-a') == 1,
			"Value looks wrong for 1 boolean found"
		);
		OK(
			!$h->Values('-b'), 	"Value looks wrong for 1 boolean not found"
		);
	}
}
# Check for multiple declaration.
{
my $error = 'USAGE: Getopt-OO.t [-a ]
    -a  help for a
Found following errors:
Options "-a" declared more than once.
';
	my $h = eval {
		Getopt::OO->new(
			[ '-a' ],
			'-a' => {help => 'help for a'},
			'-a' => {help => 'help for a'},
		);
	};
	my $e = $@;
	OK($@ eq $error, "$@");
}
# Check that values returns are right.
{
	my $h;
	eval {
		$h = Getopt::OO->new(
			[],
			'-a'	=> {},
			'-b'	=> {},
			'--a'	=> {},
		);
	};
	OK(!$@,  "Crashed");
	OK(!$h->Values(), "Empty failed");
	my @argv = qw (-a --a -b);
	my @test = @argv;
	eval {
		$h = Getopt::OO->new(
			\@argv,
			'-a'	=> {},
			'-b'	=> {},
			'--a'	=> {},
		);
	};
	OK(!$@,  "Crashed");
	OK($h->Values() == scalar(@test), "Not empty failed");
	OK(join(' ', $h->Values()) eq join(' ', @test), "Order failed");
}
# Check return values and types are right.
{
	 my @argv = qw (-abcde b c0 d0 d1 e0 e1 -c c1 -e e2 e3);
	 my $h = Getopt::OO->new(\@argv,
		'-a' => {},
		'-b' => { n_values => 1, },
		'-c' => { n_values => 1, multiple => 1, },
		'-d' => { n_values => 2, },
		'-e' => { n_values => 2, multiple => 1, },
	 );
	 my $n_options = $h->Values();
	 my $a = $h->Values('-a');
	 my $b = $h->Values('-b');
	 my @c = $h->Values('-c');
	 my @d = $h->Values('-d');
	 my @e = $h->Values('-e');
	OK($n_options && $n_options == 7, "Wrong number of args");
	OK($a && $a == 1, 					"-a Failed");
	OK($b && $b eq 'b',					"-b Failed");
	OK(@c && @c == 2 
		&& $c[0] eq 'c0'
		&& $c[1] eq 'c1',				"-c Failed");
	OK(@d && @d == 2 
		&& $d[0] eq 'd0'
		&& $d[1] eq 'd1',				"-d Failed");
	OK(@e && @e == 2 && ref $e[0] 
		&& ref $e[0] eq 'ARRAY'
		&& $e[0]->[0] eq 'e0'
		&& $e[0]->[1] eq 'e1'
		&& ref $e[1] eq 'ARRAY'
		&& $e[1]->[0] eq 'e2'
		&& $e[1]->[1] eq 'e3' ,			"-e Failed");
}
# Test Verbose and Debug.
{
	use Getopt::OO qw(Debug Verbose);
	OK(Verbose() == 0,		"Verbose off by default is ok.");
	Verbose(1);
	OK(Verbose() == 1,		"Verbose on works.");
	Verbose(0);
	OK(Verbose(0) == 0,		"Verbose off works.");
	OK(Debug() == 0,		"Debug off by default is ok.");
	Debug(1);
	OK(Debug() == 1,		"Debug on works.");
	Debug(0);
	OK(Debug(0) == 0,		"Debug off works.");

	my $tmp = "/tmp/t.$$";
	my @debug_test = ("testing Debug\n");
	my $fh = IO::File->new("> $tmp");
	Debug(1);
	Debug($fh);
	Debug(@debug_test);
	$fh->close();
	$fh = IO::File->new("$tmp");
	my @x = <$fh>;
	OK("@x" eq "@debug_test", "Debug redirect Failed");

	my @verbose_test = ("testing Verbose\n");
	$fh = IO::File->new("> $tmp");
	Verbose(1);
	Verbose($fh);
	Verbose(@verbose_test);
	$fh->close();
	$fh = IO::File->new("$tmp");
	 @x = <$fh>;
	OK("@x" eq "@verbose_test", "Verbose redirect Failed ok.");
	unlink($tmp);
}
# test callback.
{
	my $x;
	my $h = Getopt::OO->new(
		[ '-a' ],
		'-a' => { callback => sub{$x = 27; 0 }, }
	);
	OK($x == 27, 		"callback with no error works.");
}
# Test callback.
{
my $error = 'USAGE: Getopt-OO.t [-a ]
Found following errors:
Option callback for "-a" returned an error:
	callback with an error
';
	my $x;
	eval {
		my $h = Getopt::OO->new(
			[ '-a' ],
			'-a' => { callback => sub{$x = 27; "callback with an error" }, }
		);
	};
	OK($@ eq $error,		"callback with error FAILED:\n" . $@);
}
# Check ClientDate.
{
	my $h = Getopt::OO->new(
		[ '-a' ],
		'-a' => {}
	);
	my $x = $h->ClientData('-a');
	$h->ClientData('-a', '27');
	my $y = $h->ClientData('-a');
	OK(!defined $x && $y == 27,				"ClientData failed.\n");
}
# Check for required.
{
	my $h;
	eval {
		$h = Getopt::OO->new(
			[ '-b', '--b' ],
			required => [ '-a', '-bb',  ],
			'-a' => { help => 'help for -a', },
			'-b' => { help => 'help for -b', },
			'--b' => { help => 'help for --b', },
		);
	};
	OK($@ && $@ =~ /Missing required/,	"found missing required failed.\n");
	$h = eval {
		Getopt::OO->new(
			[ '-b', '-a' ],
			required => [ '-a' ],
			'-a' => {},
			'-b' => {},
		);
	};
	OK(!$@,					 			"found required FAILED.\n");
}
# Check mutual exclusive.
{
	my $h = eval {
		Getopt::OO->new(
			['-a'],
			mutual_exclusive => [
				[ '-b', '-a' ],
			],
			'-a' => {},
			'-b' => {},
		);
	};
	OK($@ eq '', 						"no mutual_exclusive ok.\n");
	$h = eval {
		Getopt::OO->new(
			['-a', '-b'],
			mutual_exclusive => [
				[ '-b', '-a' ],
			],
			'-a' => {},
			'-b' => {},
		);
	};
	OK($@ =~ /Found mutually exclusive/,"simple bad mutual_exclusive ok.\n");
}
# Check to make sure we catch bad argument.
{
	my $h = eval {
		Getopt::OO->new (
			[ qw (-a -b -c) ],
			'-av' => {}
		)
	};

	OK($@, 'xxx');
}
# Check multi_options
{
	my $h;
	eval {
		$h = Getopt::OO->new(
			[qw(--a 1 2 3)],
			'--a' => {
				multi_value => 1,
			},
		);
	};
	OK($@ && $@ =~ /Failed to find end to multi_value/,
		"Unterminated multi-value"
	);
	eval {
		$h = Getopt::OO->new(
			[qw(--a 1 2 3 -)],
			'--a' => {
				multi_value => 1,
			},
		);
	};
	OK(!$@, "multi_value failed:\n" . $@);
	OK(join(' ', $h->Values('--a')) eq '1 2 3',
		"non multiple multi-value"
	);
	eval {
		$h = Getopt::OO->new(
			[qw(--a 1 2 3 - --a 1 2 3 -)],
			'--a' => {
				multi_value => 1,
			},
		);
	};
	OK($@ && $@ =~ /encountered more than once/,
		"bad multiple multi-value"
	);
	eval {
		$h = Getopt::OO->new(
			[qw(--a 1 2 3 - --a 4 5 6 -)],
			'--a' => {
				multi_value => 1,
				multiple => 1,
			},
		);
	};
	OK(!$@, "good multiple multi-value\n" . $@);
	if (!$@) {
		my @values = $h->Values('--a');
		OK(@values && @values == 2 && ref $values[0] && ref $values[1]
			&& join(' ', (map {@$_} @values)) eq '1 2 3 4 5 6',
			"good multiple multi-value return."
		);
	}
}
# tests for other_values.
{
	my $m1 = "USAGE: Getopt-OO.t value_1 ... value_n
Found following errors:
other_values: Can't have multi_value
";
	eval {
		my $handle = Getopt::OO->new(
			[],
			other_values => { n_values => 1, multi_value => 1, },
		);
	};
	OK(
		$@ eq $m1,
		"other_value check for multi_value.\n$@"
	);
	my $m2 = 'USAGE: Getopt-OO.t
Found following errors:
other_values: bad tags: x_values
';
	eval {
		my $handle = Getopt::OO->new(
			[],
			other_values => { x_values => 1},
		);
	};
	OK(
		$@ eq $m2,
		"Check for bad tag name\n$@"
	);
	my $m3 = 'USAGE: Getopt-OO.t
Found following errors:
other_values: n_values must be a number.
';
	eval {
		my $handle = Getopt::OO->new(
			[],
			other_values => { n_values => 'x'},
		);
	};
	OK(
		$@ eq $m3,
		"Check for bad n_values\n$@"
	);
	my $m4 = 'USAGE: Getopt-OO.t
Found following errors:
other_values: should be reference to a hash.
';
	eval {
		my $handle = Getopt::OO->new(
			[],
			other_values => 'x',
		);
	};
	OK(
		$@ eq $m4,
		"Check for bad other_values tag\n$@"
	);
	my $m5 = 'USAGE: Getopt-OO.t value
';
	my $handle;
	eval {
		$handle = Getopt::OO->new(
			[ 'x', ],
			other_values => { n_values => 1},
		);
	};
	OK(
		!$@ && $handle && $handle->Help() eq $m5,
		"Check help other_value for n_value == 1\n$@:"
			. (($handle) ? $handle->Help() : ''),
	);
	my $m6 = 'USAGE: Getopt-OO.t value_1 value_2
';
	eval {
		$handle = Getopt::OO->new(
			[ 'x', 'y' ],
			other_values => { n_values => 2},
		);
	};
	OK(
		!$@ && $handle && $handle->Help() eq $m6,
		"Check help for other_value n_value == 2\n$@:"
			. (($handle) ? $handle->Help() : ''),
	);
	my $m7 = 'USAGE: Getopt-OO.t value_1 ... value_3
';
	my @r1;
	eval {
		$handle = Getopt::OO->new(
			[ 'x', 'y', 'z' ],
			other_values => {
				n_values => 3,
				callback=> sub {
					@r1 = $_[0]->Values($_[1]); 0
				},
			},
		);
	};
	OK(
		!$@ && $handle && $handle->Help() eq $m7,
		"Check help for other_value n_value == 2\n$@:"
			. (($handle) ? $handle->Help() : ''),
	);
	OK(
		scalar $handle->Values('other_values') == 3 &&
		join(' ', $handle->Values('other_values')) eq 'x y z',
		'Check return on other_values'
	);
	OK(
		@r1 == 3 && join(' ', @r1) eq 'x y z',
		'Check return on other_values callback'
	);
	my $m9 = 'USAGE: Getopt-OO.t file_1 ... file_n
';
	eval {
		$handle = Getopt::OO->new(
			[ 'x', 'y', 'z' ],
			other_values => { help => 'file_1 ... file_n' },
		);
	};
	OK(
		!$@ && $handle && $handle->Help() eq $m9,
		"Check help for other_value help\n$@:"
			. (($handle) ? $handle->Help() : ''),
	);
	my $m8 = 'USAGE: Getopt-OO.t value_1 ... value_3
Found following errors:
other_values callback returned an error:
	Fail callback
';
	eval {
		$handle = Getopt::OO->new(
			[ 'x', 'y', 'z' ],
			other_values => {
				n_values => 3,
				callback=> sub {'Fail callback'},
			},
		);
	};
	OK(
		$@ && $@ eq $m8,
		'Check fail on other_value callback.',
	);
}
# Complicated -- check everything.
{
	my $help = 'USAGE: Getopt-OO.t [-bc b_arg c_arg] [--b b_arg --c ... - --d ... -] -a  --a value
    Arguments --a, -a are required.
    Arguments "-a -b" are mutually exclusive.
    Argument -c may occur more than once.
    --a         help for --a
    --b arg     help for --b
    --c ... -   help for --c
    --d ... -   help for --d
    -a          help for -a
    -b arg      help for -b
    -c arg      help for -c
';
	my $h;
	my @argv = qw(-a --a --c 1 2 3 - abc);
	eval {
		$h = Getopt::OO->new(
			\@argv,
			'required'			=> [ '-a', '--a', ],
			'mutual_exclusive'	=> [ [ '-a', '-b', ], ],
			'other_values'		=> { n_values => 1},
			'-a' => {'help'		=> 'help for -a'},
			'-b' => {
				'help'			=> 'help for -b',
				'n_values'		=> 1,
			},
			'-c' => {
				'help'			=> 'help for -c',
				'n_values'		=> 1,
				'multiple'		=> 1,
			},
			'--a' => {
				'help'			=> 'help for --a',
			},
			'--b' => {
				'help'			=> 'help for --b',
				'n_values'		=> 1,
			},
			'--c' => {
				'help'			=> 'help for --c',
				'multi_value'	=> 1,
			},
			'--d' => {
				'help'			=> 'help for --d',
				'multi_value'	=> 1,
			},
		);
	};
	OK(! $@,					"    Crashed: error $@");
	OK(defined $h, 				"    No handle returned");
	if (defined $h) {
		OK($h->isa('Getopt::OO'),	"    Handle looks wrong.");
		OK(
			$h->Help() eq $help, 
			"    Help looks wrong:\n" . $h->Help()
		);
		OK(
			$h->Values('--a') == 1, 
			"Values not right for arg found"
		);
		OK(
			$h->Values('--c') == 3
			&& join(' ', $h->Values('--c')) eq '1 2 3'
			, 'multi-values return looks right'
		);
		OK(!$h->Values('--d'), 'multi-values empty return looks right');
		OK(@argv == 1 && $argv[0] eq 'abc', "other_values is broken.");
	}
}
# Check other_values to make sure it is right and wrong.
{
	my $h;
	eval {
		$h = Getopt::OO->new(
			[],
			'other_values' => { n_values => 1},
		);
	};
	OK(
		!$@, "No required values check for other_values:n_values\n"
	);
	eval {
		$h = Getopt::OO->new(
			[],
			'required_values' => [ 'other_values' ],
		);
	};
	OK($@, "Check for bad tag name\n");
	eval {
		$h = Getopt::OO->new(
			[],
			'required' => [ 'other_values' ],
		);
	};
	OK($@, "required values check for other_values:value is bad\n");
	eval {
		$h = Getopt::OO->new(
			['abc'],
			'required' => [ 'other_values' ],
		);
	};
	OK(!$@, "required values check for other_values:value is good\n");
	my @argv = qw(-a abc def);
	eval {
		$h = Getopt::OO->new(
			\@argv,
			'-a' => { 'n_values' => 1, },
			'other_values' => { n_values => 1},
		);
	};
	OK(@argv == 1 && $argv[0] eq 'def', "argv not right.");
	my @x;
	eval {
		$h = Getopt::OO->new(
			[qw (a b)],
			'other_values' => {
				'n_values' => 1,
			},
		);
	};
	OK($@, "check for number values on other_values:1");
	eval {
		$h = Getopt::OO->new(
			[qw (a b)],
			'other_values' => {
				'n_values' => 2,
			},
		);
	};
	OK(!$@, "check for number values on other_values:2");
	eval {
		$h = Getopt::OO->new(
			[qw (a b)],
			'other_values' => {
				'n_values' => 3,
			},
		);
	};
	OK($@, "check for number values on other_values:3");
	eval {
		$h = Getopt::OO->new(
			[],
			'other_values' => {
				help => 'help',
				callback => sub {
					@x = $_[0]->Values($_[1]);
					0;
				},
			},
		);
	};
	OK(
		!$@ && @x == 0,
		"check for no values returned on other_values callback"
	);
	eval {
		my @args = qw(a b c);
		my @a = @args;
		$h = Getopt::OO->new(
			\@args,
		);
		unless (@args && "@args" eq "@a") {
			die "Failed to leave args alone if assigned to other values"
		}
		if (my @x = $h->Values()) {
			unless (@x == 1 && $x[0] eq 'other_values') {
				die "Failed to find 'other_values'.\n";
			}
			my @values = $h->Values('other_values');
			unless (@values && "@values" eq "@a") {
				die "Failed to get correct return values from ",
					"Values('other_values')\n";
			}
		}
		else {
			die "Failed to set the Values for values found.\n"
		}
	};
	OK(!$@, $@);
	{
		my $s =  "USAGE: Getopt-OO.t\n"
				. "Found following errors:\n"
				. "other_values n_values set to 0 but received 3 values.\n";
		eval {
			my @args = qw(a b c);
			$h = Getopt::OO->new(
				\@args,
				'other_values' => {
					'n_values' => 0,
				}
			);
		};
		OK($@ && $@ eq $s, "Failed to detect other_values received but "
			. "other_values n_values set to 0.\n"
		);
	}
}
# Tests for other_values.
