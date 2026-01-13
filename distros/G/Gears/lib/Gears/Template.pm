package Gears::Template;
$Gears::Template::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Path::Tiny qw(path);
use Gears::X::Template;

has param 'encoding' => (
	isa => Str,
	default => 'UTF-8',
);

has param 'paths' => (
	isa => ArrayRef [Str],
	default => sub { [] },
);

# implements actual rendering of a template
# must be reimelemented
sub _render_template ($self, $template_content, $vars)
{
	...;
}

sub process ($self, $template, $vars = {})
{
	my $ref = ref $template;

	# A GLOB or an IO object will be read and returned as a SCALAR template
	# No reference means a file name
	if (!$ref) {
		$template = $self->_read_file($self->_find_template($template));
	}
	elsif ($ref eq 'GLOB' || $template isa 'IO::Handle') {
		$template = $self->_read_file($template);
	}
	elsif ($ref eq 'SCALAR') {
		$template = $template->$*;
	}
	else {
		Gears::X::Template->raise("Template must be either a SCALAR or GLOB reference, or an IO::Handle object");
	}

	return $self->_render_template($template, $vars);
}

sub _find_template ($self, $name)
{
	for my $p ($self->paths->@*) {
		my $file = "$p/$name";
		return $file if -f $file;
	}

	Gears::X::Template->raise("Template file not found: $name");
}

sub _read_file ($self, $file)
{
	my $text;

	if (ref $file) {
		# read the entire file
		local $/ = undef;

		# make sure to properly rewind the handle after we read from it
		my $pos = tell $file;
		$text = readline $file;
		seek $file, $pos, 0;
	}
	else {
		$text = path($file)->slurp(
			{binmode => ':encoding(' . $self->encoding . ')'}
		);
	}

	return $text;
}

__END__

=head1 NAME

Gears::Template - Abstract template processing interface

=head1 SYNOPSIS

	package My::Gears::Template;

	use v5.40;
	use Mooish::Base -standard;

	extends 'Gears::Template';

	sub _render_template ($self, $template_content, $vars)
	{
		my $result = $template_content;
		# Simple variable substitution
		foreach my $key (keys %$vars) {
			my $value = $vars->{$key};
			$result =~ s/\{\{$key\}\}/$value/g;
		}
		return $result;
	}

	# In your code
	use My::Gears::Template;

	my $template = My::Gears::Template->new(
		paths => ['templates']
	);

	# Process a file template
	my $output = $template->process('page.tmpl', {title => 'Hello'});

	# Process a scalar reference
	my $output = $template->process(\'Hello {{name}}', {name => 'World'});

=head1 DESCRIPTION

Gears::Template is an abstract base class for template processing functionality.
It provides file handling, template discovery, and encoding support, but leaves
the actual template processing to subclasses. This allows different template
engines to be used with a consistent interface.

The template processor can work with templates from multiple sources: files
(found via search paths), scalar references, or file handles. It handles
encoding automatically and provides a simple API for template processing.

=head1 EXTENDING

This template processor is abstract by design. A subclass must be created that
implements the C<_render_template> method to define how templates are actually
processed.

Here is how a minimal working template subclass could be implemented:

	package My::Gears::Template;

	use v5.40;
	use Mooish::Base -standard;

	extends 'Gears::Template';

	sub _render_template ($self, $template_content, $vars)
	{
		# Simple variable substitution
		foreach my $key (keys %$vars) {
			$template_content =~ s/\Q{{$key}}\E/$vars->{$key}/g;
		}

		return $template_content;
	}

For a more advanced template engine using Template::Toolkit:

	package My::Gears::Template::TT;

	use v5.40;
	use Mooish::Base -standard;
	use Template;

	extends 'Gears::Template';

	has param 'tt' => (
		isa => InstanceOf ['Template'],
		default => sub { Template->new },
	);

	sub _render_template ($self, $template_content, $vars)
	{
		my $output;
		Gears::X::Template->raise($self->tt->error)
			unless $self->tt->process(\$template_content, $vars, \$output);

		return $output;
	}

=head1 INTERFACE

=head2 Attributes

=head3 encoding

A string specifying the encoding to use when reading template files. Defaults
to C<'UTF-8'>.

I<Available in constructor>

=head3 paths

An array reference of directory paths where template files should be searched
for. Defaults to an empty array. Templates are searched in the order paths are
specified, and the first matching file is used.

I<Available in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can be passed in C<%args>.

=head3 process

	$output = $template->process($template, $vars = {})

Processes a template with the provided variables and returns the result. The
C<$template> argument can be:

=over

=item * A string - interpreted as a filename to be found via C<find_template>

=item * A SCALAR reference - the template content itself

=item * A GLOB reference or IO::Handle - an open file handle to read from

=back

The optional C<$vars> hash reference contains variables to be used during
template processing.

Returns the processed template as a string.

