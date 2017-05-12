# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl Getopt-Mixed-Help.t'
# Without Makefile it could be called with `perl -I../lib Getopt-Mixed-Help.t'

#########################################################################

use Test::More tests => 494;

use Config;
use File::Spec;

require_ok 'Getopt::Mixed::Help';

# for successful run with test coverage use:
# cover -delete
# HARNESS_PERL_SWITCHES=-MDevel::Cover=-silent,on,-summary,off make test
# cover
my $perl = $Config{perlpath};
$perl .= ' ' . $ENV{HARNESS_PERL_SWITCHES}
    if defined $ENV{HARNESS_PERL_SWITCHES};

#########################################################################
# identical part of messages:
my $re_msg_tail =
    qr/Getopt::Mixed::Help at .*Getopt-Mixed-Help\.t line \d{2,}\.?$/;

# some parameter lists used later:
my @parameter	= ('<filenames>...'		=> 'filenames to be used');
my @boolean	= ('b>boolean'			=> 'a boolean (flag)');
my @mand_str	= ('s>mandatory-string=s'	=> 'a mandatory string');
my @mand_int	= ('i>mandatory-integer=i'	=> 'a mandatory integer');
my @mand_float	= ('f>mandatory-float=f'	=> 'a mandatory real number');
my @opt_str	= ('t>optional-string:s'	=> 'an optional string');
my @opt_int	= ('j>optional-integer:i'	=> 'an optional integer');
my @opt_float	= ('g>optional-float:f'		=> 'an optional real number');
my @long_str_opt= ('long-optional-string:s'	=> 'another optional string');
my @all_options	= (@boolean, @long_str_opt,
		   @mand_str, @mand_int, @mand_float,
		   @opt_str,  @opt_int,  @opt_float,
		   '(*)' => '(*) some more text',
		   'ENV' => 'TEST_OPT_', 'ENV_' => 'TEST_OPT_');
my @all		= (@parameter, @all_options);

#########################################################################
# failing tests:
my ($volume, $directories, ) = File::Spec->splitpath($0);
(my $path = $0) =~ s|[^/]+$||;

eval { Getopt::Mixed::Help::import(1) };
like($@, qr/^bad usage of $re_msg_tail/, 'bad import should fail');

eval { import Getopt::Mixed::Help };
like($@,
     qr/^no parameter passed to $re_msg_tail/,
     'import without parameter list should fail');

eval { import Getopt::Mixed::Help() };
like($@,
     qr/^no parameter passed to $re_msg_tail/,
     'import with empty parameter list should fail');

eval { import Getopt::Mixed::Help('') };
like($@,
     qr/^unbalanced parameter list passed to $re_msg_tail/,
     'import with single parameter should fail');

eval { import Getopt::Mixed::Help(@parameter, '') };
like($@,
     qr/^unbalanced parameter list passed to $re_msg_tail/,
     'import with three parameters (list + single) should fail');

eval { import Getopt::Mixed::Help('x' => 'x') };
like($@,
     qr/^bad option x passed to $re_msg_tail/,
     'import with bad option should fail');
eval { import Getopt::Mixed::Help('x>xx yy' => 'zz') };
like($@,
     qr/^bad option x>xx yy passed to $re_msg_tail/,
     'import with bad option should fail');

eval { import Getopt::Mixed::Help('->debug' => 'x') };
like($@,
     qr/^bad renaming of debug in $re_msg_tail/,
     'import with bad renaming of debug should fail');

eval { import Getopt::Mixed::Help('->default' => 'x') };
like($@,
     qr/^default text must contain %s in $re_msg_tail/,
     'import with bad renaming of default should fail');

eval { import Getopt::Mixed::Help('->help' => 'x') };
like($@,
     qr/^bad renaming of help in $re_msg_tail/,
     'import with bad renaming of help should fail');

#########################################################################
# simple succeeding tests:
sub test_simple_import($$$$$)
{
    my ($description, $r_options, $r_argv, $option_var, $expected) = @_;
    local $_;
    # reset option variables:
    foreach (keys %main::)
    { $$_ = undef if m/^opt_/ or /^optUsage$/ }
    # initialise arguments:
    @ARGV = @$r_argv;
    # test:
    eval { import Getopt::Mixed::Help(@$r_options) };
    is($@, '', $description.' - import failed');
    is(scalar(@ARGV), 0, $description.' - parameters are left');
    is($$option_var, $expected, $description);
}

eval { import Getopt::Mixed::Help(@parameter) };
is($@, '', 'import with option-less parameter list');
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--] <filenames>...

filenames to be used

EOU
   'usage of option-less parameter list');

test_simple_import('boolean option is set (short)',
		   \@boolean, [qw(-b)],
		   'opt_boolean', 1);
test_simple_import('boolean option is not set',
		   \@boolean, [],
		   'opt_boolean', undef);
test_simple_import('boolean option is set (long)',
		   \@boolean, [qw(--boolean)],
		   'opt_boolean', 1);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -b|--boolean
              a boolean (flag)
EOU
   'usage of boolean option');

$ENV{TEST_OPT_BOOLEAN} = '1';
test_simple_import('unset boolean and specific ENV',
		   ['ENV' => 'TEST_OPT_', @boolean], [], 'opt_boolean', 1);
delete $ENV{TEST_OPT_BOOLEAN};
$ENV{TEST_OPT__} = 'boolean';
test_simple_import('unset boolean and global ENV',
		   ['ENV_' => 'TEST_OPT_', @boolean], [], 'opt_boolean', 1);
delete $ENV{TEST_OPT__};

test_simple_import('mandatory string option (short, separate)',
		   \@mand_str, [qw(-s text1)],
		   'opt_mandatory_string', 'text1');
test_simple_import('mandatory string option (short, concatenated)',
		   \@mand_str, [qw(-stext2)],
		   'opt_mandatory_string', 'text2');
test_simple_import('mandatory string option (long, separate)',
		   \@mand_str, [qw(--mandatory-string text3)],
		   'opt_mandatory_string', 'text3');
test_simple_import('mandatory string option (long, concatenated)',
		   \@mand_str, [qw(--mandatory-string=text4)],
		   'opt_mandatory_string', 'text4');
test_simple_import('mandatory string option (short, separate, minus)',
		   \@mand_str, [qw(-s -text1)],
		   'opt_mandatory_string', '-text1');
test_simple_import('mandatory string option (short, concatenated, minus)',
		   \@mand_str, [qw(-s-text2)],
		   'opt_mandatory_string', '-text2');
test_simple_import('mandatory string option (long, separate, minus)',
		   \@mand_str, [qw(--mandatory-string -text3)],
		   'opt_mandatory_string', '-text3');
test_simple_import('mandatory string option (long, concatenated, minus)',
		   \@mand_str, [qw(--mandatory-string=-text4)],
		   'opt_mandatory_string', '-text4');
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -s|--mandatory-string <string>
              a mandatory string
EOU
   'usage of mandatory string option');

test_simple_import('mandatory integer option (short, separate)',
		   \@mand_int, [qw(-i 1)],
		   'opt_mandatory_integer', 1);
test_simple_import('mandatory integer option (short, concatenated)',
		   \@mand_int, [qw(-i2)],
		   'opt_mandatory_integer', 2);
test_simple_import('mandatory integer option (long, separate)',
		   \@mand_int, [qw(--mandatory-integer 3)],
		   'opt_mandatory_integer', 3);
test_simple_import('mandatory integer option (long, concatenated)',
		   \@mand_int, [qw(--mandatory-integer=4)],
		   'opt_mandatory_integer', 4);
test_simple_import('mandatory integer option (short, separate, negative)',
		   \@mand_int, [qw(-i -1)],
		   'opt_mandatory_integer', -1);
test_simple_import('mandatory integer option (short, concatenated, negative)',
		   \@mand_int, [qw(-i-2)],
		   'opt_mandatory_integer', -2);
test_simple_import('mandatory integer option (long, separate, negative)',
		   \@mand_int, [qw(--mandatory-integer -3)],
		   'opt_mandatory_integer', -3);
test_simple_import('mandatory integer option (long, concatenated, negative)',
		   \@mand_int, [qw(--mandatory-integer=-4)],
		   'opt_mandatory_integer', -4);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -i|--mandatory-integer <integer>
              a mandatory integer
EOU
   'usage of mandatory integer option');

test_simple_import('mandatory real number option (short, separate)',
		   \@mand_float, [qw(-f 1.1)],
		   'opt_mandatory_float', 1.1);
test_simple_import('mandatory real number option (short, concatenated)',
		   \@mand_float, [qw(-f2.2)],
		   'opt_mandatory_float', 2.2);
test_simple_import('mandatory real number option (long, separate)',
		   \@mand_float, [qw(--mandatory-float 3.3)],
		   'opt_mandatory_float', 3.3);
test_simple_import('mandatory real number option (long, concatenated)',
		   \@mand_float, [qw(--mandatory-float=4.4)],
		   'opt_mandatory_float', 4.4);
test_simple_import('mandatory real number option (short, separate, negative)',
		   \@mand_float, [qw(-f -1.1)],
		   'opt_mandatory_float', -1.1);
test_simple_import('mandatory real number option (short, concatenated, negative)',
		   \@mand_float, [qw(-f-2.2)],
		   'opt_mandatory_float', -2.2);
test_simple_import('mandatory real number option (long, separate, negative)',
		   \@mand_float, [qw(--mandatory-float -3.3)],
		   'opt_mandatory_float', -3.3);
test_simple_import('mandatory real number option (long, concatenated, negative)',
		   \@mand_float, [qw(--mandatory-float=-4.4)],
		   'opt_mandatory_float', -4.4);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -f|--mandatory-float <float>
              a mandatory real number
EOU
   'usage of mandatory real number option');

test_simple_import('optional string option (short, empty)',
		   \@opt_str, [qw(-t)],
		   'opt_optional_string', '');
test_simple_import('optional string option (short, concatenated)',
		   \@opt_str, [qw(-ttext2)],
		   'opt_optional_string', 'text2');
test_simple_import('optional string option (long, empty)',
		   \@opt_str, [qw(--optional-string)],
		   'opt_optional_string', '');
test_simple_import('optional string option (long, concatenated)',
		   \@opt_str, [qw(--optional-string=text4)],
		   'opt_optional_string', 'text4');
test_simple_import('optional string option (unused)',
		   \@opt_str, [],
		   'opt_optional_string', undef);
test_simple_import('optional string option (short, concatenated, minus)',
		   \@opt_str, [qw(-t-text2)],
		   'opt_optional_string', '-text2');
test_simple_import('optional string option (long, concatenated, minus)',
		   \@opt_str, [qw(--optional-string=-text4)],
		   'opt_optional_string', '-text4');
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -t|--optional-string [<string>]
              an optional string
EOU
   'usage of optional string option');

test_simple_import('optional integer option (short, empty)',
		   \@opt_int, [qw(-j)],
		   'opt_optional_integer', 1);
test_simple_import('optional integer option (short, concatenated)',
		   \@opt_int, [qw(-j2)],
		   'opt_optional_integer', 2);
test_simple_import('optional integer option (long, empty)',
		   \@opt_int, [qw(--optional-integer)],
		   'opt_optional_integer', 1);
test_simple_import('optional integer option (long, concatenated)',
		   \@opt_int, [qw(--optional-integer=4)],
		   'opt_optional_integer', 4);
test_simple_import('optional integer option (unused)',
		   \@opt_int, [],
		   'opt_optional_integer', undef);
test_simple_import('optional integer option (short, concatenated, negative)',
		   \@opt_int, [qw(-j-2)],
		   'opt_optional_integer', -2);
test_simple_import('optional integer option (long, concatenated, negative)',
		   \@opt_int, [qw(--optional-integer=-4)],
		   'opt_optional_integer', -4);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -j|--optional-integer [<integer>]
              an optional integer
EOU
   'usage of optional integer option');

test_simple_import('optional real number option (short, empty)',
		   \@opt_float, [qw(-g)],
		   'opt_optional_float', 0.0);
test_simple_import('optional real number option (short, concatenated)',
		   \@opt_float, [qw(-g2.2)],
		   'opt_optional_float', 2.2);
test_simple_import('optional real number option (long, empty)',
		   \@opt_float, [qw(--optional-float)],
		   'opt_optional_float', 0.0);
test_simple_import('optional real number option (long, concatenated)',
		   \@opt_float, [qw(--optional-float=4.4)],
		   'opt_optional_float', 4.4);
test_simple_import('optional real number option (unused)',
		   \@opt_float, [],
		   'opt_optional_float', undef);
test_simple_import('optional real number option (short, concatenated, negative)',
		   \@opt_float, [qw(-g-2.2)],
		   'opt_optional_float', -2.2);
test_simple_import('optional real number option (long, concatenated, negative)',
		   \@opt_float, [qw(--optional-float=-4.4)],
		   'opt_optional_float', -4.4);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -g|--optional-float [<float>]
              an optional real number
EOU
   'usage of optional real number option');

test_simple_import('long optional string option (empty)',
		   ['->-' => '', @long_str_opt],
		   [qw(--long-optional-string)],
		   'opt_long_optional_string', '');
test_simple_import('long optional string option (concatenated)',
		   ['->-' => '', @long_str_opt],
		   [qw(--long-optional-string=text5)],
		   'opt_long_optional_string', 'text5');
test_simple_import('long optional string option (unused)',
		   ['->-' => '', @long_str_opt], [],
		   'opt_long_optional_string', undef);
test_simple_import('long optional string option (concatenated, minus)',
		   ['->-' => '', @long_str_opt],
		   [qw(--long-optional-string=-text6)],
		   'opt_long_optional_string', '-text6');
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  --long-optional-string [<string>]
              another optional string
EOU
   'usage of long-only optional string option');

test_simple_import('mandatory string with value description',
		   ['o>option=s mandatory string' => 'description'], [],
		   'opt_option', undef);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -o|--option <mandatory string>
              description
EOU
   'usage of mandatory string with value description');

test_simple_import('mandatory integer with value description',
		   ['o>option=i mandatory integer' => 'description'], [],
		   'opt_option', undef);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -o|--option <mandatory integer>
              description
EOU
   'usage of mandatory integer with value description');

test_simple_import('mandatory real number with value description',
		   ['o>option=f mandatory real number' => 'description'], [],
		   'opt_option', undef);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -o|--option <mandatory real number>
              description
EOU
   'usage of mandatory real number with value description');

test_simple_import('optional string with value description',
		   ['o>option:s optional string' => 'description'], [],
		   'opt_option', undef);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -o|--option [<optional string>]
              description
EOU
   'usage of optional string with value description');

test_simple_import('optional integer with value description',
		   ['o>option:i optional integer' => 'description'], [],
		   'opt_option', undef);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -o|--option [<optional integer>]
              description
EOU
   'usage of optional integer with value description');

test_simple_import('optional real number with value description',
		   ['o>option:f optional real number' => 'description'], [],
		   'opt_option', undef);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -o|--option [<optional real number>]
              description
EOU
   'usage of optional real number with value description');

test_simple_import('enumeration with value description',
		   ['o>option=s {a,b,c}' => 'description'], [],
		   'opt_option', undef);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -o|--option {a,b,c}
              description
EOU
   'usage of enumeration with value description');

#########################################################################
# tests using default values from Perl constants:

sub test_simple_default($$$$$$$)
{
    my ($description, $r_options, $r_argv, $constant, $default_val,
	$option_var, $expected) = @_;
    local $_;
    # reset option variables:
    foreach (keys %main::)
    { $$_ = undef if m/^opt_/ or /^optUsage$/ }
    # initialise arguments:
    @ARGV = @$r_argv;
    # test:
    eval {
	import constant $constant => $default_val;
	import Getopt::Mixed::Help(@$r_options);
    };
    is($@, '', $description.' - eval failed');
    is(scalar(@ARGV), 0, $description.' - parameters are left');
    if (ref($expected) eq 'ARRAY')
    {
	is_deeply($$option_var, $expected, $description);
    }
    else
    {
	is($$option_var, $expected, $description);
    }
}

test_simple_default('mandatory integer option (using default)',
		    ['i>mandatory-integer-1=i' => 'a mandatory integer'],
		    [],
		    'DEFAULT_MANDATORY_INTEGER_1', 2,
		    'opt_mandatory_integer_1', 2);
test_simple_default('mandatory integer option (overriding default)',
		    ['i>mandatory-integer-2=i' => 'a mandatory integer'],
		    [qw(-i 1)],
		    'DEFAULT_MANDATORY_INTEGER_2', 2,
		    'opt_mandatory_integer_2', 1);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -i|--mandatory-integer-2 <integer>
              a mandatory integer (defaults to 2)
EOU
   'usage of mandatory integer option with default constant');
test_simple_default('mandatory integer option (overriding default text)',
		    ['->default' => ', default is %s',
		     'i>mandatory-integer-3=i' => 'a mandatory integer'],
		    [],
		    'DEFAULT_MANDATORY_INTEGER_3', 2,
		    'opt_mandatory_integer_3', 2);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -i|--mandatory-integer-3 <integer>
              a mandatory integer, default is 2
EOU
   'test with renamed default option should succeed');
test_simple_default('mandatory multiple integer option (using defaults)',
		    ['i>>mandatory-integer-4=i' => 'some mandatory integers'],
		    [],
		    'DEFAULT_MANDATORY_INTEGER_4', [ 4, 2 ],
		    'opt_mandatory_integer_4', [4, 2] );
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--]

options:  -i|--mandatory-integer-4 <integer>
              some mandatory integers (defaults to 4, 2)
EOU
   'usage of mandatory integer option with default constant array');
eval {

    import constant DEFAULT_XXX => {};
    import Getopt::Mixed::Help('x>xxx' => 'yy');
 };
like($@,
     qr/^.* constants as default values are not yet supported in $re_msg_tail/,
     'non-simple constant should fail');

#########################################################################
# complicated succeeding tests:
my @all_option_vars = qw(
			 opt_boolean
			 opt_long_optional_string
			 opt_mandatory_string
			 opt_mandatory_integer
			 opt_mandatory_float
			 opt_optional_string
			 opt_optional_integer
			 opt_optional_float
);
sub test_whole_import($$$$)
{
    my ($description, $r_argv, $r_expected_option_values, $r_expected_argv)
	= @_;
    local $_;
    # reset option variables:
    foreach (keys %main::)
    { $$_ = undef if m/^opt_/ or /^optUsage$/ }
    # initialise arguments:
    @ARGV = @$r_argv;
    # test:
    eval { import Getopt::Mixed::Help(@all) };
    is($@, '', $description.' - import failed');
    foreach (0..6)
    {
	my $option_var = $all_option_vars[$_];
	is($$option_var, $r_expected_option_values->[$_],
	   $description.' - '.$option_var);
    }
    is(@ARGV, @$r_expected_argv, $description.' - parameters are incorrect');
}

test_whole_import('no option passed',
		[],
		[undef, undef, undef, undef, undef, undef, undef],
		[]);
is($optUsage,
   <<EOU,
usage: Getopt-Mixed-Help.t [<options>] [--] <filenames>...

filenames to be used

options:  -b|--boolean
              a boolean (flag)
          --long-optional-string [<string>]
              another optional string
          -s|--mandatory-string <string>
              a mandatory string
          -i|--mandatory-integer <integer>
              a mandatory integer
          -f|--mandatory-float <float>
              a mandatory real number
          -t|--optional-string [<string>]
              an optional string
          -j|--optional-integer [<integer>]
              an optional integer
          -g|--optional-float [<float>]
              an optional real number

(*) some more text
EOU
   'usage of all options together');
test_whole_import('all short optional options as defaults',
		  [qw(-t -j -g)],
		  [undef, undef, undef, undef, undef, '', 1, 0.0],
		  []);
test_whole_import('all short optional options as defaults, parameter',
		  [qw(-t -j -g -- 1.0)],
		  [undef, undef, undef, undef, undef, '', 1, 0.0],
		  [1.0]);
test_whole_import('all short optional options as defaults, boolean',
		  [qw(-b -t -j -g)],
		  [1, undef, undef, undef, undef, '', 1, 0.0],
		  []);
test_whole_import('all short optional options as defaults, boolean, parameter',
		  [qw(-b -t -j -g -- 2.0)],
		  [1, undef, undef, undef, undef, '', 1, 0.0],
		  [2.0]);
test_whole_import('all short optional options',
		  [qw(-t42 -j47 -g4.2)],
		  [undef, undef, undef, undef, undef, '42', 47, 4.2],
		  []);
test_whole_import('all short optional options, parameter',
		  [qw(-j42 -g4.7 -t47 3.0)],
		  [undef, undef, undef, undef, undef, '47', 42, 4.7],
		  [3.0]);
test_whole_import('all short optional options, boolean',
		  [qw(-g4.2 -j47 -t42 -b)],
		  [1, undef, undef, undef, undef, '42', 47, 4.2],
		  []);
test_whole_import('all short optional options, boolean, parameter',
		  [qw(-t47 -b -g4.7 -j42 4.0)],
		  [1, undef, undef, undef, undef, '47', 42, 4.7],
		  [4.0]);
test_whole_import('all options and two parameters',
		  [qw(-t42 -b -s-b -i-1 -g4.2 --long-optional-string=42 -f-1.2 -j47 5 0)],
		  [1, '42', '-b', -1, -1.2, '42', 47, 4.2],
		  [5, 0]);
test_whole_import('all options and three parameters with --',
		  [qw(-t47 -b -s -s -i -2 -g4.7 -f -2.3 --long-optional-string=-47 -j42 -- -g -j -t)],
		  [1, '-47', '-s', -2, -2.3, '47', 42, 4.7],
		  [qw(-g -j -t)]);
$ENV{TEST_OPT_MANDATORY_INTEGER} = 42;
$ENV{TEST_OPT_OPTIONAL_STRING} = 'Nvironment';
test_whole_import('two single options coming from the environment',
		  [],
		  [undef, undef, undef, 42, undef, 'Nvironment', undef, undef],
		  []);
test_whole_import('single environment option gets overwritten',
		  ['--optional-string=string'],
		  [undef, undef, undef, 42, undef, 'string', undef, undef],
		  []);
delete $ENV{TEST_OPT_MANDATORY_INTEGER};
delete $ENV{TEST_OPT_OPTIONAL_STRING};
$ENV{TEST_OPT__} = 'mandatory-string=all_together optional-integer=42';
test_whole_import('two options coming from one environment variable',
		  [],
		  [undef, undef, 'all_together', undef, undef, undef, 42, undef],
		  []);
test_whole_import('single combined environment option gets overwritten',
		  ['--mandatory-string=override'],
		  [undef, undef, 'override', undef, undef, undef, 42, undef],
		  []);
$ENV{TEST_OPT_MANDATORY_STRING} = 'Nvironment';
test_whole_import('environment overwrite',
		  [],
		  [undef, undef, 'Nvironment', undef, undef, undef, 42, undef],
		  []);
delete $ENV{TEST_OPT_MANDATORY_STRING};
delete $ENV{TEST_OPT__};

#########################################################################
# tests needing a subprocess:
eval {
 SKIP: {
	# As Getopt::Mixed and ourself will sometimes fail with exit(-1)
	# the following last tests are more complicated.  As I/O
	# redirection doesn't seem to work correctly everywhere (failing
	# cpan-testers tests for those tests), we test that first and skip
	# the tests if we forsee any problems.
	my $cmd = "perl -e 'die'";
	my $output = `$cmd 2>&1`;
	skip "redirection of output doesn't work as expected ($?): $output", 22
	    if $? == 0 or $output !~ m/^Died at -e line 1.*$/;
	# This still doesn't seem to help on windows based platforms
	# so we skip on them anyway:
	skip "the tests with redirection of output don't work on Windows", 22
	    if $^O =~ m/^Cygwin|^MSWin32/i;

	local %ENV;
	$ENV{PERL5LIB} = join $Config{path_sep}, @INC;

	$cmd = $perl.' '.File::Spec->catpath($volume, $directories, 'fail.pl');
	$output = `$cmd -x 2>&1`;
	isnt($?, 0, 'unknown option should fail');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
Unknown option: x
Try `fail.pl --help' for more information.
EOM
	   'unknown option should fail with error message');

	$output = `$cmd -? 2>&1`;
	isnt($?, 0, 'calling for help (-?) should fail');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
usage: fail.pl [<options>] [--]

options:  -b|--boolean
              a boolean (flag)
EOM
	   'calling for help (-?) should fail with usage text');

	$output = `$cmd -h 2>&1`;
	isnt($?, 0, 'calling for help (-h) should fail');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
usage: fail.pl [<options>] [--]

options:  -b|--boolean
              a boolean (flag)
EOM
	   'calling for help (-h) should fail with usage text');

	$output = `$cmd parameter 2>&1`;
	isnt($?, 0, 'calling with parameter should fail');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
usage: fail.pl [<options>] [--]

options:  -b|--boolean
              a boolean (flag)
EOM
	   'calling with parameter should fail with usage text');

	$cmd = ($perl." -e '".
		'use Getopt::Mixed::Help("'.
		join('", "', @all, 'd>debug' => 'turn on debugging').
		'");'.
		"' -- -d -s Test -g 5.0 -i 42 x y z");
	$output = `$cmd 2>&1`;
	is($?, 0, 'test with normal debug option should succeed');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
options:  
          \$opt_boolean:              undef
          \$opt_long_optional_string: undef
          \$opt_mandatory_string:     "Test"
          \$opt_mandatory_integer:    42
          \$opt_mandatory_float:      undef
          \$opt_optional_string:      undef
          \$opt_optional_integer:     undef
          \$opt_optional_float:       5.0
          \$opt_debug:                1
parameter:
          "x"
          "y"
          "z"
EOM
	   'normal debugging option and output');

	$cmd = ($perl." -e '".
		'use Getopt::Mixed::Help("'.
		join('", "', @all, '->help' => 'H>Hilfe').
		'");'.
		"' --");
	$output = `$cmd -H 2>&1`;
	isnt($?, 0, 'calling for renamed help should fail');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
usage: -e [<options>] [--] <filenames>...

filenames to be used

options:  -b|--boolean
              a boolean (flag)
          --long-optional-string [<string>]
              another optional string
          -s|--mandatory-string <string>
              a mandatory string
          -i|--mandatory-integer <integer>
              a mandatory integer
          -f|--mandatory-float <float>
              a mandatory real number
          -t|--optional-string [<string>]
              an optional string
          -j|--optional-integer [<integer>]
              an optional integer
          -g|--optional-float [<float>]
              an optional real number

(*) some more text
EOM
	   'calling for renamed help should fail with usage text');

	$cmd = ($perl." -e '".
		'use Getopt::Mixed::Help("'.
		join('", "', @all, '->help' => 'H>Hilfe').
		'");'.
		"' --");
	$output = `$cmd -h 2>&1`;
	isnt($?, 0, 'calling for help after rename should fail');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output,
	   "Unknown option: h\nTry `-e --Hilfe' for more information.\n",
	   'calling for help after rename should fail with usage text');

	$cmd = ($perl." -e '".
		'use Getopt::Mixed::Help("'.
		join('", "', @all, '->debug' => 'verbose',
		     'v>verbose' => 'turn on debugging').
		'");'.
		"' -- -s Test -g 5.0 -v -i 42 4 2 4.7");
	$output = `$cmd 2>&1`;
	is($?, 0, 'test with renamed debug option should succeed');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
options:  
          \$opt_boolean:              undef
          \$opt_long_optional_string: undef
          \$opt_mandatory_string:     "Test"
          \$opt_mandatory_integer:    42
          \$opt_mandatory_float:      undef
          \$opt_optional_string:      undef
          \$opt_optional_integer:     undef
          \$opt_optional_float:       5.0
          \$opt_verbose:              1
parameter:
          4
          2
          4.7
EOM
	   'renamed debugging option and output');

	$cmd = ($perl." -e '".
		'use Getopt::Mixed::Help("'.
		join('", "',
		     @parameter,
		     '->options' => 'switches',
		     @all_options,
		     '->usage' => 'use this like').
		'");'.
		"' --");
	$output = `$cmd -? 2>&1`;
	isnt($?, 0, 'calling for help with altered texts should fail');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
use this like: -e [<switches>] [--] <filenames>...

filenames to be used

switches:  -b|--boolean
               a boolean (flag)
           --long-optional-string [<string>]
               another optional string
           -s|--mandatory-string <string>
               a mandatory string
           -i|--mandatory-integer <integer>
               a mandatory integer
           -f|--mandatory-float <float>
               a mandatory real number
           -t|--optional-string [<string>]
               an optional string
           -j|--optional-integer [<integer>]
               an optional integer
           -g|--optional-float [<float>]
               an optional real number

(*) some more text
EOM
	   'calling for help with altered texts should fail with alt. usage text');

	$cmd = ($perl." -e '".
		'use Getopt::Mixed::Help("'.
		join('", "',
		     'd>debug' => 'turn on debugging',
		     'i>>integer=i' => 'a mandatory integer').
		'");'.
		"' -- -d -i 1 -i 2 -i 3");
	$output = `$cmd 2>&1`;
	is($?, 0, 'test with debug output and multiple options should succeed');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
options:  
          \$opt_debug:   1
          \$opt_integer: (1, 2, 3)
EOM
	   'correct debugging output for multiple options');

	$cmd = ($perl." -e '".
		'use constant DEFAULT_INTEGER => [4, 2]; '.
		'use Getopt::Mixed::Help("'.
		join('", "',
		     'd>debug' => 'turn on debugging',
		     'i>>integer=i' => 'a mandatory integer').
		'");'.
		"' -- -d");
	$output = `$cmd 2>&1`;
	is($?, 0, 'test with debug output and multiple default should succeed');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	is($output, <<EOM,
options:  
          \$opt_debug:   1
          \$opt_integer: (4, 2)
EOM
	   'correct debugging output for multiple default');
    }
};
is($@, '', 'tests with subprograms should not fail the surrounding eval');

#########################################################################
# succeeding tests with multiple support:
sub test_multiple_import($$$$$)
{
    my ($description, $r_options, $r_argv,
	$r_expected_option_values, $r_expected_argv) = @_;
    local $_;
    # reset option variables:
    foreach (keys %main::)
    { $$_ = undef if m/^opt_/ or /^optUsage$/ }
    # initialise arguments:
    @ARGV = @$r_argv;
    # test:
    eval { import Getopt::Mixed::Help(@$r_options) };
    is($@, '', $description.' - import failed');
    foreach (0..6)
    {
	my $option_var = $all_option_vars[$_];
	is_deeply($$option_var, $r_expected_option_values->[$_],
	   $description.' - '.$option_var);
    }
    is(@ARGV, @$r_expected_argv, $description.' - parameters are incorrect');
}

test_multiple_import
    ('concat test - multiples not activated',
     \@all,
     [qw(-t4 -b -s-b -t2 -b -i-1 -g4.2 --long-optional-string=42 -j47 -g0.5
	 -i -3 -f -1.2 -f2.0 -f 3.4 -j-5 --long-optional-string=42 5 0)],
     [1, '42', '-b', -3, 3.4, '2', -5, 4.7],
     [5, 0]);

test_multiple_import
    ('concat test - no multiples',
     [@all, '->multiple' => ''],
     [qw(-t42 -b -s-b -i-1 -g4.2 --long-optional-string=42 -f-1.2 -j47 5 0)],
     [1, '42', '-b', -1, -1.2, '42', 47, 4.2],
     [5, 0]);

test_multiple_import
    ('concat test - multiples, empty',
     [@all, '->multiple' => ''],
     [qw(-t4 -b -s-b -t2 -b -i-1 -g4.2 --long-optional-string=42 -j47 -g0.5
	 -i -3 -f -1.2 -f2.0 -f 3.4 -j-5 --long-optional-string=42 5 0)],
     [2, '4242', '-b', -4, 4.2, '42', 42, 4.7],
     [5, 0]);

test_multiple_import
    ('concat test - multiples, comma',
     [@all, '->multiple' => ', '],
     [qw(-t4 -b -s-b -t2 -b -i-1 -g4.2 --long-optional-string=42 -j47 -g0.5
	 -i -3 -f -1.2 -f2.0 -f 3.4 -j-5 --long-optional-string=42 5 0)],
     [2, '42, 42', '-b', -4, 4.2, '4, 2', 42, 4.7],
     [5, 0]);

$ENV{TEST_OPT_MANDATORY_INTEGER} = 42;
$ENV{TEST_OPT_OPTIONAL_STRING} = 'Nvironment';
test_multiple_import
    ('concat test - multiples, with environment',
     [@all, '->multiple' => ''],
     [qw(-t4 -b -s-b -t2 -b -i-1 -g4.2 --long-optional-string=42 -j47 -g0.5
	 -i -3 -f -1.2 -f2.0 -f 3.4 -j-5 --long-optional-string=42 5 0)],
     [2, '4242', '-b', -4, 4.2, '42', 42, 4.7],
     [5, 0]);
delete $ENV{TEST_OPT_MANDATORY_INTEGER};
delete $ENV{TEST_OPT_OPTIONAL_STRING};

test_multiple_import
    ('array test - no multiples',
     [@all, '->multiple' => undef],
     [qw(-t42 -b -s-b -i-1 -g4.2 --long-optional-string=42 -f-1.2 -j47 5 0)],
     [1, '42', '-b', -1, -1.2, '42', 47, 4.2],
     [5, 0]);

test_multiple_import
    ('array test - multiples',
     [@all, '->multiple' => undef],
     [qw(-t4 -b -s-b -t2 -b -i-1 -g4.2 --long-optional-string=42 -j47 -g0.5
	 -i -3 -f -1.2 -f2.0 -f 3.4 -j-5 --long-optional-string=42 5 0)],
     [[1, 1], ['42', '42'], '-b', [-1, -3], [-1.2, '2.0', 3.4],
      ['4', '2'], [47, -5], [4.2, 0.5]],
     [5, 0]);

$ENV{TEST_OPT_MANDATORY_INTEGER} = 42;
$ENV{TEST_OPT_OPTIONAL_STRING} = 'Nvironment';
test_multiple_import
    ('array test - multiples, ignore ENV',
     [@all, '->multiple' => undef],
     [qw(-t4 -b -s-b -t2 -b -i-1 -g4.2 --long-optional-string=42 -j47 -g0.5
	 -i -3 -f -1.2 -f2.0 -f 3.4 -j-5 --long-optional-string=42 5 0)],
     [[1, 1], ['42', '42'], '-b', [-1, -3], [-1.2, '2.0', 3.4],
      ['4', '2'], [47, -5], [4.2, 0.5]],
     [5, 0]);
delete $ENV{TEST_OPT_MANDATORY_INTEGER};
delete $ENV{TEST_OPT_OPTIONAL_STRING};

test_multiple_import
    ('selected multiples - other options, multiple',
     [@all,
      'd>>directory=s directory' =>
      'directory to search in (more than one possible)',
      '>>long-opt=s' => 'yet another long option'],
     [qw(-t4 -b -s-b -t2 -b -i-1 -g4.2 -d a --long-optional-string=42
	 -j47 -g0.5 -d /b -i -3 -f -1.2 -d. -f2.0 -f 3.4 -j-5 --long-opt=x
	 --long-optional-string=42 --long-opt=y -d./c 5 0)],
     [1, '42', '-b', -3, 3.4, '2', -5, 4.7],
     [5, 0]);
{
    no warnings 'once';
    is_deeply($opt_directory, [qw(a /b . ./c)],
	      'selected multiples - normal multiple option');
    is_deeply($opt_long_opt, [qw(x y)],
	      'selected multiples - long multiple option');
}
test_multiple_import
    ('selected multiples - other options, single',
     [@all,
      '>>long-opt=s' => 'yet another long option',
      'd>>directory=s directory' =>
      'directory to search in (more than one possible)'],
     [qw(-t4 -b -s-b -t2 -b -i-1 -g4.2 -da --long-optional-string=42
	 -j47 -g0.5 -i -3 -f -1.2 -f2.0 -f 3.4 -j-5
	 --long-optional-string=42 --long-opt=x 5 0)],
     [1, '42', '-b', -3, 3.4, '2', -5, 4.7],
     [5, 0]);
{
    no warnings 'once';
    is($opt_directory, 'a', 'selected multiples - normal single option');
    is($opt_long_opt, 'x', 'selected multiples - long single option');
}
eval { import Getopt::Mixed::Help('d>>dir' => 'dir', '->multiple' => ',') };
like($@,
     qr/^multiple option support per .* is mutually exclusive in $re_msg_tail/,
     'multiple support per option and globally should fail');
eval { import Getopt::Mixed::Help('->multiple' => ',', 'd>>dir' => 'dir') };
like($@,
     qr/^multiple option support per .* is mutually exclusive in $re_msg_tail/,
     'multiple support globally and per option should fail');

#########################################################################
# 2nd tests needing a subprocess (see 1st bunch for details):
eval {
 SKIP: {
	my $cmd = "perl -e 'die'";
	my $output = `$cmd 2>&1`;
	skip "redirection of output doesn't work as expected ($?): $output", 2
	    if $? == 0 or $output !~ m/^Died at -e line 1.*$/;
	skip "the tests with redirection of output don't work on Windows", 2
	    if $^O =~ m/^Cygwin|^MSWin32/i;

	local %ENV;
	$ENV{PERL5LIB} = join $Config{path_sep}, @INC;

	$cmd = ($perl." -e '".
		'use Getopt::Mixed::Help("'.
		join('", "', @all, 'd>debug' => 'turn on debugging',
		     '->multiple' => ', ').
		'");'.
		"' -- -d -sTest -sCase -i5 -tx -t -tz -g5.0 -g-47.42 -i 42");
	$output = `$cmd 2>&1`;
	is($?, 0, 'concat test - multiples, debug - should succeed');
	$output =~ s/Devel::Cover.*//s;	# ignore add. output of Devel::Cover 
	    is($output, <<EOM,
options:  
          \$opt_boolean:              undef
          \$opt_long_optional_string: undef
          \$opt_mandatory_string:     "Test, Case"
          \$opt_mandatory_integer:    47
          \$opt_mandatory_float:      undef
          \$opt_optional_string:      "x, , z"
          \$opt_optional_integer:     undef
          \$opt_optional_float:       -42.42
          \$opt_debug:                1
EOM
	       'concat test - multiples, debug - output');
    }
};
is($@, '', 'tests with 2nd subprograms should not fail the surrounding eval');
