use Test::More;
use JSON::RPC::Dispatcher;

my @valid = (
		# some of these are absurd, but the spec says any string is a valid method name.
		'name1',
		'name.foo',
		'name/foo',
		'[name]',
		'a name with spaces',
		'{name}foo',
		'http://www.foo.com/foo',
		'!@%!@#%!@#$!@#$!@#%',
		'გთხოვთ ახლავე',
		'0',
		'false',
		'0 but true',
);

my @invalid = (
		'rpc.foo',
		'rpc.გთხოვთ ახლავე',
		'',
		undef,
		{},
		[qw(ref)],
);

plan tests=>@valid + @invalid;

my $dist = JSON::RPC::Dispatcher->new();
foreach my $valid (@valid) { 
	my $accepted = eval { 
		$dist->register($valid=>sub { return 'ok' });
		return 1;
	};
	if($accepted) { 
		pass("Accepted a valid symbol name");
	} else { 
		fail("Rejected a valid symbol name: $valid with error $@");
	}
};

foreach my $invalid (@invalid) { 
	my $accepted = eval { 
		$dist->register($invalid=>sub { return 'ok' });
		return 1;
	};
	if($accepted) { 
		fail("Accepted an invalid symbol name: $invalid");
	} else { 
		pass("Rejected an nvalid symbol name");
	}
}

