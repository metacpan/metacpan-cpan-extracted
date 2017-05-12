use Hook::LexWrap;
print "1..54\n";

sub ok   { print "ok $_[0]\n" }
sub fail(&) { print "not " if $_[0]->() }

sub actual { ok $_[0]; }


actual 1;

{ 
	my $lexical = wrap actual =>
			pre  => sub { ok 2 },
			post => sub { ok 4 };

	wrap actual => pre => sub { $_[0]++ };

	my $x = 2;
	actual $x;
	1;	# delay destruction
}

wrap *main::actual, post => sub { ok 6 };

actual my $x = 4;

no warnings qw/bareword reserved/;
eval { wrap other => pre => sub { print "not ok 7\n" } } or ok 7;

eval { wrap actual => pre => 1 } and print "not ";
ok 8;

eval { wrap actual => post => [] } and print "not ";
ok 9;

BEGIN { *{CORE::GLOBAL::sqrt} = sub { CORE::sqrt(shift) } }
wrap 'CORE::GLOBAL::sqrt', pre => sub { $_[0]++ };

$x = 99;
ok sqrt($x);

sub temp { ok $_[0] };

my $sub = wrap \&temp,
	pre  => sub { ok $_[0]-1 },
	post => sub { ok $_[0]+1 };

$sub->(12);
temp(14);

{
	local $SIG{__WARN__} = sub { ok 15 };
	eval { wrap \&temp, pre => sub { ok $_[0]-1 }; 1 } and ok 16;
}

use Carp;

sub wrapped_callee {
	return join '|', caller;
}

wrap wrapped_callee =>
	pre =>sub{
		print "not " unless $_[0] eq join '|', caller;
		ok 17
	},
	post=>sub{
		print "not " unless $_[0] eq join '|', caller;
		ok 18
	};

sub raw_callee {
	return join '|', caller;
}

print "not " unless wrapped_callee(scalar raw_callee); ok 19;

sub scalar_return { return 'string' }
wrap scalar_return => post => sub { $_[-1] .= 'ent' };
print "not " unless scalar_return eq 'stringent'; ok 20;

sub list_return { return (0..9) }
wrap list_return => post => sub { @{$_[-1]} = reverse @{$_[-1]} };
my @result = list_return;
for (0..9) {
	print "not " and last unless $_ + $result[$_] == 9;
}
ok 21;

sub shorted_scalar { return 2 };
wrap shorted_scalar => pre => sub { $_[-1] = 1 };
fail { shorted_scalar != 1 }; ok 22;

sub shorted_list { return (2..9) };
{
	my $lexical = wrap shorted_list => pre => sub { $_[-1] = [1..9] };
	fail { (shorted_list)[0] != 1 }; ok 23;
}
{
	my $lexical = wrap shorted_list => pre => sub { $_[-1] = 1 };
	fail { (shorted_list)[0] != 1 }; ok 24;
}
{
	my $lexical = wrap shorted_list=>pre => sub { @{$_[-1]} = (1..9) };
	fail { (shorted_list)[0] != 1 }; ok 25;
}
{
	my $lexical = wrap shorted_list=>pre => sub { @{$_[-1]} = [1..9] };
	fail { (shorted_list)[0]->[0] != 1 }; ok 26;
}
{
	my $lexical = wrap shorted_list=> post => sub { $_[-1] = [1..9] };
	fail { (shorted_list)[0] != 1 }; ok 27;
}
{
	my $lexical = wrap shorted_list => post => sub { $_[-1] = 1 };
	fail { (shorted_list)[0] != 1 }; ok 28;
}
{
	my $lexical = wrap shorted_list=>post => sub { @{$_[-1]} = (1..9) };
	fail { (shorted_list)[0] != 1 }; ok 29;
}
{
	my $lexical = wrap shorted_list=>post => sub { @{$_[-1]} = [1..9] };
	fail { (shorted_list)[0]->[0] != 1 }; ok 30;
}

sub howmany { ok 32 if @_ == 3 }

wrap howmany =>
	pre  => sub { ok 31 if @_ == 4 },
	post => sub { ok 33 if @_ == 4 };

howmany(1..3);

{
no warnings 'uninitialized';
sub wanted { 
	my $expected = $_[3];
	print 'not ' unless defined wantarray == defined $expected
			 && wantarray eq $expected;
	ok $_[1]
}

wrap wanted =>
	pre => sub {
		my $expected = $_[3];
		print 'not ' unless defined wantarray == defined $expected
				 && wantarray eq $expected;
		ok $_[0]
	},
	post => sub {
		my $expected = $_[3];
		print 'not ' unless defined wantarray == defined $expected
				 && wantarray eq $expected;
		ok $_[2]
	};

my @array  = wanted(34..36, 1);
my $scalar = wanted(37..39, "");
wanted(40..42,undef);
}

sub caller_test {
	print "not " unless (caller 0)[3] eq 'main::caller_test';  ok $_[0];
	print "not " unless (caller 1)[3] eq 'main::caller_outer'; ok $_[0]+1;
	print "not " unless (caller 2)[3] eq 'main::wrapped';      ok $_[0]+2;
	print "not " unless (caller 3)[3] eq 'main::inner';        ok $_[0]+3;
	print "not " unless (caller 4)[3] eq 'main::middle';       ok $_[0]+4;
	print "not " unless (caller 5)[3] eq 'main::outer';        ok $_[0]+5;
}

sub caller_outer {
	caller_test(@_);
}

sub wrapped {
	caller_outer(@_);
}

sub outer  { middle(@_) }
sub middle { inner(@_) }
sub inner  { wrapped(@_) }

outer(43..48);

wrap wrapped =>
	pre => sub {},
	post => sub {};

wrap wrapped =>
	pre => sub {},
	post => sub {};

wrap wrapped =>
	pre => sub {},
	post => sub {};

outer(49..54);
