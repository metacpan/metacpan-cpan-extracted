use Test::More 0.98;

my $class;
BEGIN { $class  = 'Distribution::Cooker' };
my $local_class = 'Local::Cooker';
my $module = 'Foo::Bar';
my $dist   = 'Foo-Bar';
my $cooker;

package Local::Cooker {
	use parent ( $class );

	sub template_dir { 'templates' }

	sub cook { 'Buster' }
	sub prompt { return }
	}

subtest setup => sub {
	can_ok( $local_class, qw(pre_run run post_run) );

	$cooker = $local_class->new;
	isa_ok( $cooker, $local_class );
	isa_ok( $cooker, $class );
	can_ok( $cooker, qw(pre_run run post_run) );

	ok( $cooker->pre_run,  "pre_run is no_op and returns true"  );
	ok( $cooker->post_run, "post_run is no_op and returns true" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# mock the cook method so we don't do anything
{
no strict 'refs';
no warnings 'redefine';
is( $local_class->cook, 'Buster', "cook has been overridden" );

# try it with a module name
subtest module_name => sub {
	ok( my $cooker = $local_class->run( $module, 'description', $module ),
		"run returns something that is true" );
	isa_ok( $cooker, $local_class );

	is( $cooker->module, $module, "Set module to $module" );
	is( $cooker->dist, $dist, "Set module to $dist" );
	};

# try it with prompting
subtest prompting => sub {
	my $module = 'Baz::Quux';
	my $dist   = 'Baz-Quux';

	local *{"${class}::prompt"} = sub { $module };

	ok( my $cooker = $local_class->run( $module ), "run returns something that is true" );
	isa_ok( $cooker, $local_class );

	is( $cooker->module, $module, "Set module to $module" );
	is( $cooker->dist, $dist, "Set module to $dist" );
	};

# try it with no module name
subtest no_module_name => sub {
	my $module = 'Baz::Quux';
	my $dist   = 'Baz-Quux';

	local *{"${local_class}::prompt"} = sub { return };
	is( $local_class->prompt, undef, "prompt has been mocked as undef" );

	my $rc = eval { $local_class->run };
	my $at = $@;
	ok( defined $at, "eval failed for run() with no module name" );
	};

}

done_testing();
