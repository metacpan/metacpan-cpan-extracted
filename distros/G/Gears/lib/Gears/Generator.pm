package Gears::Generator;
$Gears::Generator::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Generator;
use Path::Tiny qw(path);

has param 'base_dir' => (
	coerce => (InstanceOf ['Path::Tiny'])
		->plus_coercions(
			Str, q{ Path::Tiny::path($_) },
		),
);

has param 'name_filters' => (
	isa => ArrayRef [CodeRef],
	default => sub { [] },
);

has param 'content_filters' => (
	isa => ArrayRef [CodeRef],
	default => sub { [] },
);

sub get_template ($self, $name)
{
	my $dir = $self->base_dir->child($name);
	Gears::X::Generator->raise("invalid directory $name")
		unless $dir->is_dir;

	my @all_items;
	my $iter = $dir->iterator({recurse => true});
	while (my $item = $iter->()) {
		next if $item->is_dir;
		push @all_items, $item;
	}

	return \@all_items;
}

sub generate ($self, $name, $target_dir)
{
	my $template_items = $self->get_template($name);
	my $base = $self->base_dir->child($name);
	my $target_path = path($target_dir);

	Gears::X::Generator->raise("target directory does not exist: $target_dir")
		unless $target_path->is_dir;

	my @generated;
	for my $item ($template_items->@*) {
		my $target_file = $target_path->child($item->relative($base));

		my $content = $item->slurp({binmode => ':encoding(UTF-8)'});
		($target_file, $content) = $self->_process_file($target_file, $content);

		$target_file = path($target_file);
		$target_file->parent->mkdir;
		push @generated, [$target_file, $content];

		Gears::X::Generator->raise("file already exists: $target_file, aborting")
			if $target_file->exists;
	}

	foreach my $item (@generated) {
		$item->[0]->spew({binmode => ':encoding(UTF-8)'}, $item->[1]);
	}

	return [map { $_->[0] } @generated];
}

sub _process_file ($self, $name, $content)
{
	foreach my $filter ($self->name_filters->@*) {
		$name = $filter->($name);
	}

	foreach my $filter ($self->content_filters->@*) {
		$content = $filter->($content);
	}

	return ($name, $content);
}

__END__

=head1 NAME

Gears::Generator - Copy and transform files

=head1 SYNOPSIS

	use Gears::Generator;

	my $gen = Gears::Generator->new(
		base_dir => 'templates',
		name_filters => [
			sub ($name) {
				return $name =~ s{app.pl$}{my_app.pl}r;
			},
		],
		content_filters => [
			sub ($content) {
				return $content =~ s{App$}{My::App}rg;
			},
		],
	);

	# Generate files from template
	$gen->generate('app', 'my_app');

=head1 DESCRIPTION

Gears::Generator is a simple file scaffolding tool that generates file
structures from templates. It reads template directories and modifies their
names and contents with custom subroutines, then writes the results to a target
directory.

This tool is deliberately not very advanced. It does not use full templating
engine to generate file contents. It simply copies the files and does optional
filtering. This way it can be used to move things like examples into the local
directory automatically. If you need more control over file names and their
contents, overriding C<_process_file> method will give you full control over
the process of building final file content.

=head1 INTERFACE

=head2 Attributes

=head3 base_dir

The base directory where template directories are located. May be a string or a
L<Path::Tiny> instance. Will be turned into the latter.

I<Required in constructor>

=head3 name_filters

An array reference of filters to use against file names. Each filter is a
subroutine that takes a single value and returns the transformed value. Defaults
to an empty array.

I<Available in constructor>

=head3 content_filters

An array reference of filters to use against file contents. Each filter is a
subroutine that takes a single value and returns the transformed value. Defaults
to an empty array.

I<Available in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can be passed in C<%args>.

=head3 get_template

	$files = $gen->get_template($name)

Returns an array reference of L<Path::Tiny> objects representing all files in
the template directory specified by C<$name>. The template directory is located
under C<base_dir>.

=head3 generate

	$files = $gen->generate($template_name, $target_dir)

Generates files from the template C<$template_name> into C<$target_dir>. File
names are processed with L</name_filters>, while their contents are processed
by L</content_filters>.

Returns an array reference of L<Path::Tiny> objects representing the generated
files.

