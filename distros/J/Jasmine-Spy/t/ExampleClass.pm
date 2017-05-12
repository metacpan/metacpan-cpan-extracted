package ExampleClass;

sub new {
	return bless({}, __PACKAGE__);
}

sub foo {
	return 'foo';
}

sub bar {
	return 'bar';
}

return 42;
