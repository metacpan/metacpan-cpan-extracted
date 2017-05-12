#!perl

# tests for select-one / select-multi
use warnings FATAL => 'all';
use strict;

=for Example:

=item select-one

	source:

	<select name="foo">
		<option>one</option>
		<option>two</option>
	</select>
	<select name="foo">
		<option>one</option>
		<option>two</option>
	</select>

	to fill with data = { foo => [qw(one two)] }
	should be:

	<select name="foo">
		<option selected="selected">one</option>
		<option>two</option>
	</select>
	<select name="foo">
		<option>one</option>
		<option selected="selected">two</option>
	</select>

=item select-multi

	source:

	<select name="foo" multiple="multiple">
		<option>one</option>
		<option>two</option>
	</select>
	<select name="foo">
		<option>one</option>
		<option>two</option>
	</select>

	to fill with data = { foo => [qw(one two)] }
	should be:

	<select name="foo" multiple="multiple">
		<option selected="selected">one</option>
		<option selected="selected">two</option>
	</select>
	<select name="foo">
		<option selected="selected">one</option>
		<option selected="selected">two</option>
	</select>

=cut

use Test::More tests => 29;

my $mod;

$mod = 'HTML::FillInForm::Lite';
#$mod = 'HTML::FillInForm';

require_ok($mod);

my $o = $mod->new();

use constant YES => 1;
use constant NO  => 0;

sub check{
	my($output, $x_ref) = @_;
	foreach my $option(grep{ /option/ } split /\n/, $output){
		my($val, $x) = @{ shift @{$x_ref} };

		my $ok = qr/(?: $val .* selected | selected .* $val )/xmsi;

		if($x){
			like $option, $ok, sprintf '%5s : %3s', $val, 'yes';
		}
		else{
			unlike $option, $ok, sprintf '%5s : %3s', $val, 'no';
		}
	}
}

#use Smart::Comments;


pass "For select-one without option value";

my $src = <<'EOT';
	<select name="foo">
		<option>one</option>
		<option>two</option>
		<option selected="selected">three</option>
	</select>
	<select name="foo">
		<option>one</option>
		<option>two</option>
		<option selected="selected">three</option>
	</select>
EOT

my $data = { foo => [qw(one two)] };

my @expected = (
	# value => expected
	[ one   => YES ],
	[ two   => NO  ],
	[ three => NO  ],

	[ one   => NO  ],
	[ two   => YES ],
	[ three => NO  ],
);
check($o->fill(\$src, $data), \@expected);

### $o

pass "For select-one with option value";

$src = <<'EOT';
	<select name="foo">
		<option value="one">one</option>
		<option value="two">two</option>
		<option value="three" selected="selected">three</option>
	</select>
	<select name="foo">
		<option value="one">one</option>
		<option value="two">two</option>
		<option value="three" selected="selected">three</option>
	</select>
EOT

$data = { foo => [qw(one two)] };

@expected = (
	# value => expected
	[ one   => YES ],
	[ two   => NO  ],
	[ three => NO  ],

	[ one   => NO  ],
	[ two   => YES ],
	[ three => NO  ],
);
check($o->fill(\$src, $data), \@expected);
### $o


pass "For select-multi without option value";

$src = <<'EOT';
	<select name="foo" multiple="multiple">
		<option>one</option>
		<option>two</option>
		<option selected="selected">three</option>
	</select>
	<select name="foo" multiple="multiple">
		<option>one</option>
		<option>two</option>
		<option selected="selected">three</option>
	</select>
EOT


@expected = (
	# value => expected
	[ one   => YES ],
	[ two   => YES ],
	[ three => NO  ],

	[ one   => YES ],
	[ two   => YES ],
	[ three => NO  ],
);

check($o->fill(\$src, $data), \@expected);
### $o

pass "For select-multi with option value";

$src = <<'EOT';
	<select name="foo" multiple="multiple">
		<option value="one">one</option>
		<option value="two">two</option>
		<option value="three" selected="selected">three</option>
	</select>
	<select name="foo" multiple="multiple">
		<option value="one">one</option>
		<option value="two">two</option>
		<option value="three" selected="selected">three</option>
	</select>
EOT


@expected = (
	# value => expected
	[ one   => YES ],
	[ two   => YES ],
	[ three => NO  ],

	[ one   => YES ],
	[ two   => YES ],
	[ three => NO  ],
);

check($o->fill(\$src, $data), \@expected);
### $o
