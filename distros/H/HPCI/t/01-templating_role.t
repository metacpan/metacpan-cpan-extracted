use strict;
use Test::More skip_all => 'Need to provide template_search_paths as a required attribute before combining the role';
use Test::Exception;
use Test::Moose;
use MooseX::ClassCompositor;
use File::Spec;
use File::Tempdir;
use File::pushd;
use Path::Class;

# We're testing a role here, so we first use the factory provided by
# MooseX::ClassCompositor to generate a class, then we test with it

my  $test_class_factory = MooseX::ClassCompositor->new(
	{class_basename => 'Test'},
	);

# Generate a class which consumes the templating role
my $template_test_class = $test_class_factory->class_for('HPCI::Template');

# Test that it posesses the expected methods and attributes
has_attribute_ok($template_test_class, 'template_renderer');
can_ok( $template_test_class, 'render_template_to_file' );

{
	# We'll now create a temp directory with a little template file in it to render
	my $tmp_dir_holder = File::Tempdir->new();
	my $temp_dir = dir($tmp_dir_holder->name);

	#Switch to the directory temporarily
	my $pushed_dir = pushd($temp_dir);

	my $instance;
	lives_ok
		{$instance = $template_test_class->new(template_search_paths => [$temp_dir])}
		'Template consumer class instantiated ok';

	# $instance->init_templating();

	# Make the template file
	my $template_filename = "template_file.template";
	my $template_output_file = $temp_dir->file($template_filename)->openw();
    $template_output_file->print('Test template <: $result :>');
    close($template_output_file);

	my $output_filename = "output_file.txt";
	$instance->render_template_to_file(
		template_name => $template_filename,
		output_file_path => $output_filename,
		rendering_variables => {
			result => 'worked!'
			},
		);

	my $content = $temp_dir->file($output_filename)->slurp();
	ok($content eq 'Test template worked!', 'Template rendering went ok');

	}

done_testing();
