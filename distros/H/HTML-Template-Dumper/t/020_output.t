
# 020_output.t - Test the output from HTML::Template::Dumper, 
# 	Data::Dumper formatter

use strict;
use warnings;
use Test::More tests => 7;
use HTML::Template::Dumper;
use Data::Dumper 'Dumper';
use Struct::Compare;
use IO::Scalar;

my %tmpl_params = (
	scalar1  => 'one', 
	scalar2  => 'two', 
	loop1    => [
		{
			loop_var1 => 'loop_one', 
			loop_var2 => 'loop_two', 
			internal_loop => [
				{ loop_var3 => '1' }, 
				{ loop_var3 => '2' }, 
			], 
		}, 
		{
			loop_var1 => 'loop_three', 
			loop_var2 => 'loop_four', 
			internal_loop => [
				{ loop_var3 => '3' }, 
				{ loop_var3 => '4' }, 
			], 
		}, 
	], 
);
my $tmpl_data = <<'TMPL';
<TMPL_VAR scalar1>
<TMPL_VAR scalar2>
<TMPL_LOOP loop1>
	<TMPL_VAR loop_var1>
	<TMPL_VAR loop_var2>
	<TMPL_LOOP internal_loop>
		<TMPL_VAR loop_var3>
	</TMPL_LOOP>
</TMPL_LOOP>
TMPL
# Need to set Data::Dumper options the same as in the 
# Data::Dumper formatter
# 
local $Data::Dumper::Indent = 0;
local $Data::Dumper::Purity = 1;
local $Data::Dumper::Terse = 1;
my $expected_output = Dumper \%tmpl_params;


my $tmpl = HTML::Template::Dumper->new(
	scalarref => \$tmpl_data, 
);
$tmpl->param( \%tmpl_params );
$tmpl->set_output_format( 'Data_Dumper' );
ok( $tmpl->get_output_format() eq 'HTML::Template::Dumper::Data_Dumper',
	"Setting output format" );

# This test is very fragile and any problems with it are 
# just as likely to be a problem with the test as a problem 
# with the module.  Consider removing it in favor of doing 
# only the parse() test.  The only justification of it is 
# that we want to test output() seperate from parse(). 
# 
ok( $tmpl->output() eq $expected_output, 
	"Output is as expected" );

my $test_data;
my $test_handle = IO::Scalar->new(\$test_data);
$tmpl->output( print_to => $test_handle );
$test_handle->close;

ok( $test_data eq $expected_output, 
	"Output is as expected on file handle" );

my $got = $tmpl->parse( $tmpl->output() );
ok( compare( $got, \%tmpl_params ), "Compare to a hashref" );


# YAML tests.  Be sure to skip them if YAML isn't installed.
# 
SKIP: {
	eval { require YAML };
	skip 'YAML not installed', 3 if $@;

	$tmpl->set_output_format( 'YAML' );
	ok( $tmpl->get_output_format() eq 'HTML::Template::Dumper::YAML',
		"Setting output format" );
	
	my $expected_output = YAML::Dump(\%tmpl_params);

	# Another fragile test.
	ok( $tmpl->output eq $expected_output, 
		"Output is as expected for YAML" );
	
	ok( compare( $tmpl->parse( $tmpl->output ), \%tmpl_params ), 
		"Compare to a hashref" );
}


