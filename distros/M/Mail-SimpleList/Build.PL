#! perl

use Module::Build;

my $class = Module::Build->subclass(
	class => 'Module::Build::FilterTests',
	code  => <<'END_HERE',
	
	use File::Glob;
	use File::Spec::Functions;
	
	sub ACTION_disttest
	{
		my $self = shift;
		local $ENV{PERL_RUN_ALL_TESTS} = 1;
		$self->SUPER::ACTION_disttest( @_ );
	}
	
	sub find_test_files
	{
		my $self  = shift;
		my $tests = $self->SUPER::find_test_files( @_ );
	    
		return $tests unless $ENV{PERL_RUN_ALL_TESTS};
	
		my $test_pattern = catfile(qw( t developer *.t ) );
		unshift @$tests, File::Glob::bsd_glob( $test_pattern );
		return $tests;
	}
END_HERE
);

my $build = $class->new(
	module_name => 'Mail::SimpleList',
	license     => 'perl',
	requires    =>
	{
		Class::Roles     => '0.30',
		Email::MIME      => '1.937',
		Mail::Action     => '0.42',
		Mail::Internet   => '1.53',
		Pod::Simple      => '',
		YAML             => '0.35',
	},
	build_requires       =>
	{
		Test::Exception  => '',
		Test::MockObject => '1.07',
		Test::Simple     => '0.47',
	},
	dist_version_from => 'lib/Mail/SimpleList.pm',
	dist_author       => 'chromatic <chromatic@wgz.org>',
);

$build->create_build_script();
