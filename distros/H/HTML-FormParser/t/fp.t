# $Id: fp.t,v 1.2 2002/05/02 16:25:36 simon Exp $


use Test;

BEGIN { plan tests => 9 }

## If in @INC, should succeed
use HTML::FormParser;
ok(1);


## Test object creation

$obj = HTML::FormParser->new();
ok(defined $obj, 1, $@);



## Test basic functionality. Create a form, and make sure parsing it returns
## the correct values to the callback.

$formbits1 = '';
@inpbits1 = ();
@inpbits2 = ();

$formbits2 = '';

$form_text = "<FORM id='foo' name='bar' action='frubnitz' method='post'>";
$inp1_text = "<input type='text' name='a_text_input' value='charpooze'>";
$inp2_text = "<input type='hidden' name='a_hidden_input' value='scrofe'>";

$form = qq{
<html>
<head>
</head>
Some text that should /not/ get picked up by the parser.
$form_text

Some other text which should be ignored.
$inp1_text
$inp2_text

</form>
</body>
</html>
};

sub form_callback
{
  my ($attr, $orig) = @_;
	$formbits1 = "<FORM";
	for (qw(id name action method)) {
		$formbits1 .= " $_='$attr->{$_}'";
	}
	$formbits1 .= ">";
	$formbits2 = $orig;
}


sub input_callback
{
	my ($attr, $orig) = @_;

	my $str = "<input";
	for (qw(type name value)) {
		$str .= " $_='$attr->{$_}'";
	}
	$str .= ">";
	push @inpbits1, $str;
	push @inpbits2, $orig;
}


$obj->parse($form,
		start_form => \&form_callback,
		start_input => \&input_callback); 

ok($formbits1, $form_text, $@);
ok($formbits2, $form_text, $@);


ok($inpbits1[0], $inp1_text, $@);
ok($inpbits2[0], $inp1_text, $@);

ok($inpbits1[1], $inp2_text, $@);
ok($inpbits2[1], $inp2_text, $@);



## Now test that each callback gets called whenever it should. To do
## this we'll just store a count of how many times the callback gets 
## called, for all tags. It should be 8 times: 4 times for the form
## (start, normal, normal, end) and twice each for the input elements
## (start, normal).
$count = 0;

sub callback { ++$count }

$obj->parse($form, 
		start_form => \&callback,
		form       => \&callback,
		end_form   => \&callback,

		start_input => \&callback,
		input       => \&callback,
		end_input   => \&callback,
		);

ok($count, 8, $@);


