package HPCI::Template;

use namespace::autoclean;

use Moose::Role;

use autodie;
use Carp;
use Params::Validate ':all';
use Text::Xslate;


=head1 NAME

HPCI::Template - This role gives the consumer a simple templating engine

=head1 DESCRIPTION

Provides a method render_template_to_file that writes a target file,
using a Text::Xslate template file to define the content.

=head1 Attributes

=over 4

=item * template_search_paths - array of directory strings to search for template files

=item * _template_renderer - (internal) A Text::Xslate instance.

=back

=cut


has 'template_search_paths' => (
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	lazy    => 1,
	default => sub {
		my $self = shift;
		my $tdir = $self->_template_dir;
		my $clus = $self->cluster;
		[ "$tdir/$clus", $tdir ] },
);

	has '_template_dir' => (
		is       => 'ro',
		isa      => 'Str',
		init_arg => undef,
		lazy     => 1,
		default  => sub {
			my $self = shift;
			my $dir = File::ShareDir::module_dir('HPCI');
			print("Template search path : '$dir'\n");
			return $dir;
		},
	);

has '_template_renderer' => (
	is       => 'ro',
	isa      => 'Text::Xslate',
	init_arg => undef,
	lazy     => 1,
	default  => sub {
		my $self = shift;
		Text::Xslate->new(
			path    => $self->template_search_paths,
			verbose => 2,
		);
	},
);

=head1 Methods

=over 4

=item * render_template_to_file - generate a file from a template

Usage:
    $object->render_template_to_file(
	    template_name => "file.template",
		output_file_path => "myfile.out",
		rendering_variables => {
		    foo => "foo value",
			bar => [ qw(bar has a bunch of values ...) ],
		},
	);

=back

=cut

sub render_template_to_file {
    my $self = shift;
    my %args = validate(
        @_,
        {
            template_name => {
                type        => SCALAR,
                },
            output_file_path => {
                type        => SCALAR,
                },
            rendering_variables => {
                type        => HASHREF,
                default     => {}
                }
            }
        );

    if (defined $self->meta->get_attribute('log')){
        $self->log->info("Rendering '".$args{template_name}."' to '".$args{output_file_path}."'")
        }

    my $variables_hash = $args{rendering_variables};

    # Render the template with the variables
    my $rendered_contents = $self->_template_renderer->render($args{template_name}, $args{rendering_variables});

    # Write the result to the file
    my $output_file_path = $args{output_file_path};
    open(my $output_file, '>', "$output_file_path");
    $output_file->print($rendered_contents);
}

1;
