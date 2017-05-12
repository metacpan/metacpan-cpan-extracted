package GraphViz2::Marpa::Demo;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Config;

use Date::Format; # For time2str().
use Date::Simple;

use File::Spec;

use GraphViz2::Marpa::Config;

use HTML::Entities::Interpolate;

use Moo;

use Path::Tiny;

use Text::Xslate 'mark_raw';

use Types::Standard qw/HashRef Int/;

has authortest =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has config =>
(
	default  => sub{return GraphViz2::Marpa::Config -> new -> config},
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

our $VERSION = '2.11';

# ------------------------------------------------

sub generate_demo_environment
{
	my($self) = @_;

	my(@environment);

	# mark_raw() is needed because of the HTML tag <a>.

	push @environment,
	{left => 'Author', right => mark_raw(qq|<a href="http://savage.net.au/">Ron Savage</a>|)},
	{left => 'Date',   right => Date::Simple -> today},
	{left => 'OS',     right => 'Debian V 7'},
	{left => 'Perl',   right => $Config{version} };

	return \@environment;

} # End of generate_demo_environment.

# -----------------------------------------------

sub generate_demo_index
{
	my($self)          = @_;
	my($format)        = 'svg';
	my($data_dir_name) = 'data';
	my($html_dir_name) = 'html';

	if ($self -> authortest)
	{
		$data_dir_name = "xt/author/$data_dir_name";
		$html_dir_name = "xt/author/$html_dir_name";
	}

	my(@dot_file) = $self -> get_files($data_dir_name, 'gv');

	my(@content);
	my($dot_file);
	my($image_file, %image_file);
	my($object_file);

	for my $file_name (@dot_file)
	{
		$dot_file               = "$file_name.gv";
		$image_file             = path("$file_name.$format") -> basename;
		$image_file             = File::Spec -> catfile($html_dir_name, $image_file);
		@content                = map{$Entitize{$_} } path($dot_file) -> lines_utf8;
		$object_file            = './' . path("$file_name.svg") -> basename;
		$image_file{$file_name} =
		{
			image_file   => -e $image_file ? $image_file : '',
			image_size   => -e $image_file ? -s $image_file : 0,
			input        => $dot_file,
			input_bytes  => 'byte' . (-s $dot_file == 1 ? '' : 's'),
			input_size   => -s $dot_file,
			object_file  => $object_file,
			output       => -e $image_file && -s $image_file ? $image_file : '',
			output_bytes => 'byte' . (-e $image_file && -s $image_file == 1 ? '' : 's'),
			output_size  => -s $image_file,
			raw          => join('<br />', @content),
		};
	}

	my($config)    = $self -> config;
	my($templater) = Text::Xslate -> new
	(
		input_layer => '',
		path        => $$config{template_path},
	);
	my($count) = 0;
	my($index) = $templater -> render
	(
	'graphviz2.marpa.index.tx',
	{
		authortest => $self -> authortest,
		data       =>
		[
			map
			{
				{
					count        => ++$count,
					image_file   => mark_raw($image_file{$_}{image_file}),
					image_size   => $image_file{$_}{image_size},
					input        => mark_raw($image_file{$_}{input}),
					input_bytes  => $image_file{$_}{input_bytes},
					input_size   => mark_raw($image_file{$_}{input_size}),
					object_file  => $image_file{$_}{object_file},
					output       => mark_raw($image_file{$_}{output}),
					output_bytes => $image_file{$_}{output_bytes},
					output_size  => $image_file{$_}{output_size},
					raw          => mark_raw($image_file{$_}{raw}),
				}
			} @dot_file
		],
		default_css     => "$$config{css_url}/default.css",
		environment     => $self -> generate_demo_environment,
		fancy_table_css => "$$config{css_url}/fancy.table.css",
		version         => $VERSION,
	}
	);

	print "Finished rendering. \n";

	my($file_name) = File::Spec -> catfile($html_dir_name, 'index.html');

	open(my $fh, '>:encoding(utf-8)', $file_name);
	print $fh $index;
	close $fh;

	print "Wrote: $file_name\n";

	# Return 0 for success and 1 for failure.

	return 0;

} # End of generate_demo_index.

# ------------------------------------------------

sub get_files
{
	my($self, $dir_name, $type) = @_;

	return (sort map{s/\.$type//; $_} grep{/\.$type$/} path($dir_name) -> children);

} # End of get_files.

# --------------------------------------------------

sub justify
{
	my($self, $s) = @_;
	my($width)    = 20;

	return $s . ' ' x ($width - length $s);

} # End of justify.

# -----------------------------------------------

1;

=pod

=head1 NAME

C<GraphViz2::Marpa::Demo> - A demo page generator for C<GraphViz2::Marpa>

=head1 Synopsis

See L<GraphViz2::Marpa/Synopsis>.

=head1 Description

L<GraphViz2::Marpa> provides a Marpa-based parser for Graphviz C<dot> files,
and this module helps generate the demo page.

This module is really only of interest to the author.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<GraphViz2::Marpa> as you would for any C<Perl> module:

Run:

	cpanm GraphViz2::Marpa

or run:

	sudo cpan GraphViz2::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = GraphViz2::Marpa::Demo -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Marpa::Demo>.

Key-value pairs accepted in the parameter list:

=over 4

=item o authortest => $Boolean

This allows generate.demo.pl to control whether it's processing data/ ot xt/author/data/.

=back

=head1 Methods

=head2 generate_demo_environment()

Called by generate_demo_index().

Generates a table to be inserted into html/index.html.

See scripts/generate.demo.pl.

=head2 generate_demo_index()

Generates html/index.html.

Does not run any programs to generate other files, e.g. html/*.svg. See scripts/generate.demo.sh for that.

=head2 get_files($dir_name, $type)

Returns a sorted list of files of type (extension) $type from directory $dir_name.

=head2 justify($string)

Right justify the $string in a field of 20 spaces.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/GraphViz2-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2::Marpa>.

=head1 Author

L<GraphViz2::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
