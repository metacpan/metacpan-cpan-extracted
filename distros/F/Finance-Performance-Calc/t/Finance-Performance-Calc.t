# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-Performance-Calc.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
BEGIN { use_ok('Finance::Performance::Calc', ':all') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

=for comment out

	     {name => 'ized ROR',
	      func => \&ized_ROR,
	      args => ['25.65%',5],
	      exp  => {
		       0 => .1,
		       1 => '10%'
		      }
	     },

=cut

my @tests = (
	     {name => 'two point ROR',
	      func => \&ROR,
	      args => [bmv => 10_000, emv => 11_000],
	      exp  => {
		       0 => .1,
		       1 => '10%'
		      }
	     },
	     {name => 'two point ROR with flow',
	      func => \&ROR,
	      args => [ bmv => 10_000, emv => 10_000,
			flows => [{mvpcf=>11_800,
				   cf => -1500}]
		      ],
	      exp  => {
		       0 => 0.145631067961165,
		       1 => '14.5631067961165%'
		      }
	     },
	     {name => 'linked ROR',
	      func => \&link_ROR,
	      args => ['0.0045',
		       0.012245,
		       '2.13%'],
	      exp  => {
		       0 => 0.03845794468325,
		       1 => '3.845794468325%'
		      }
	     },
	     {name => 'ized ROR',
	      func => \&ized_ROR,
	      args => ['25.65%',5],
	      exp  => {
		       0 => 0.0467247628301146,
		       1 => '4.67247628301146%'
		      }
	     },
	    );

my @msgs = ();
for (@tests) {
    my %test = %{$_}; ## Copy test info, to be altered
    for (0,1) {
	Finance::Performance::Calc::return_percentages($_);
	my $ret_pct = Finance::Performance::Calc::return_percentages;
	push @msgs, ($ret_pct ? ', returning percentages' : '');
	for (0,1) {
	    Finance::Performance::Calc::trace($_);
	    push @msgs, (Finance::Performance::Calc::trace() ? ', with trace' : '');

	    my $title = join('',$test{name}, @msgs);
	    my $got = $test{func}->(@{$test{args}});
	    my $exp = $test{exp}->{$ret_pct};

	    ok($got eq $exp, $title) or
	      diag("\n$title\n\tGot: $got\n\tExp: $exp\n\n");

	    pop @msgs;
	}
	pop @msgs;
    }
}
