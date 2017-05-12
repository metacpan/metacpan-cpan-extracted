use strict;
use warnings FATAL => 'all';

use Test::More tests => 52;

BEGIN {
	use_ok('Exception::Class::Try::Catch');
};

can_ok('Exception::Class::Try::Catch', qw(try catch));
can_ok(__PACKAGE__, qw(try catch));

use Exception::Class 'My::Exception::Class';

try {
	My::Exception::Class->throw('my error');
} catch {
	isa_ok($_, 'Exception::Class::Base');
	isa_ok($_, 'My::Exception::Class');
	is($_->error, 'my error', 'Exception error is "my error"');
	isa_ok($_[0], 'Exception::Class::Base');
	isa_ok($_[0], 'My::Exception::Class');
	is($_[0]->error, 'my error', 'Exception error is "my error"');
};

try {
	die 'my error';
} catch {
	isa_ok($_, 'Exception::Class::Base');
	like($_->error, qr/^my error at/, 'Exception error is "my error at ..."');
	isa_ok($_[0], 'Exception::Class::Base');
	like($_[0]->error, qr/^my error at/, 'Exception error is "my error at ..."');
};

try {
	die "my error\n";
} catch {
	isa_ok($_, 'Exception::Class::Base');
	is($_->error, "my error\n", 'Exception error is "my error"');
	isa_ok($_[0], 'Exception::Class::Base');
	is($_[0]->error, "my error\n", 'Exception error is "my error"');
};

try {
	die 0;
} catch {
	isa_ok($_, 'Exception::Class::Base');
	like($_->error, qr/^0 at/, 'Exception error is "0 at ..."');
	isa_ok($_[0], 'Exception::Class::Base');
	like($_[0]->error, qr/^0 at/, 'Exception error is "0 at ..."');
};

try {
	die;
} catch {
	isa_ok($_, 'Exception::Class::Base');
	like($_->error, qr/^Died at/, 'Exception error is "Died at ..."');
	isa_ok($_[0], 'Exception::Class::Base');
	like($_[0]->error, qr/^Died at/, 'Exception error is "Died at ..."');
};

try {
	die My::NotExceptionClass::WithStringOverload->new('my error');
} catch {
	isa_ok($_, 'Exception::Class::Base');
	is($_->error, 'my error', 'Exception error is "my error"');
	isa_ok($_[0], 'Exception::Class::Base');
	is($_[0]->error, 'my error', 'Exception error is "my error"');
};

try {
	die My::NotExceptionClass::WithStringMethod->new('my error');
} catch {
	isa_ok($_, 'Exception::Class::Base');
	is($_->error, 'my error', 'Exception error is "my error"');
	isa_ok($_[0], 'Exception::Class::Base');
	is($_[0]->error, 'my error', 'Exception error is "my error"');
};

try {
	die My::NotExceptionClass->new;
} catch {
	isa_ok($_, 'Exception::Class::Base');
	like($_->error, qr/^My::NotExceptionClass=HASH\(0x[0-9a-f]+\)$/, 'Exception error is stringified ref address');
	isa_ok($_[0], 'Exception::Class::Base');
	like($_[0]->error, qr/^My::NotExceptionClass=HASH\(0x[0-9a-f]+\)$/, 'Exception error is stringified ref address');
};

try {
	die {};
} catch {
	isa_ok($_, 'Exception::Class::Base');
	like($_->error, qr/^HASH\(0x[0-9a-f]+\)$/, 'Exception error is stringified ref address');
	isa_ok($_[0], 'Exception::Class::Base');
	like($_[0]->error, qr/^HASH\(0x[0-9a-f]+\)$/, 'Exception error is stringified ref address');
};

my $input = 'value';
my $output = try { $input } catch { };
is($output, $input, 'Try in scalar context passes through scalar value');

my @input = qw(value1 value2 value3);
my @output = try { @input } catch { };
is_deeply(\@output, \@input, 'Try in list context passes through list of values');

my $error = try {
	My::Exception::Class->throw('my error');
} catch {
	$_;
};
isa_ok($error, 'Exception::Class::Base');
is($error->error, 'my error', 'Catch in scalar context passes through value');

my @values = try {
	My::Exception::Class->throw('my error');
} catch {
	('my value', $_);
};
is(scalar @values, 2, 'Catch in list context passes through list of values');
is($values[0], 'my value', 'Value is "my value"');
isa_ok($values[1], 'Exception::Class::Base');
is($values[1]->error, 'my error', 'Exception error is "my error"');

try {
	try {
		try {
			Exception::Class::Base->throw('my error');
		} catch {
			isa_ok($_, 'Exception::Class::Base');
			$_->rethrow();
		};
	} catch {
		try {
			My::Exception::Class->throw('my second error');
		} catch {
			isa_ok($_, 'My::Exception::Class');
			$_->rethrow();
		};
		$_->rethrow();
	};
} catch {
	isa_ok($_, 'My::Exception::Class');
};

package My::NotExceptionClass::WithStringOverload;
sub new { return bless(\(my $o = $_[1]), $_[0]); }
use overload '""' => sub { return ${$_[0]}; };

package My::NotExceptionClass::WithStringMethod;
sub new { return bless(\(my $o = $_[1]), $_[0]); }
sub as_string { return ${$_[0]}; }

package My::NotExceptionClass;
sub new { return bless({}, $_[0]); }
