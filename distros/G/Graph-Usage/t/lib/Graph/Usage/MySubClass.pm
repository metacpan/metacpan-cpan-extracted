#############################################################################
# empty test subclass
#
# (c) by Tels 2004-2005.
#############################################################################

package Graph::Usage::MySubClass;

use Graph::Usage;
use Exporter;

use strict;
# XXX TODO: remove the global var @files
use vars qw/$VERSION @ISA @files/;

$VERSION = '0.01';
@ISA = qw/Graph::Usage Exporter/;

sub find_file
  {
  # Take a package name and a list of include directories and find
  # the file. Returns the path if the file exists, otherwise undef.
  my ($self, $package, @inc) = @_;

  $self->output ("  In find_file($package @inc)\n");

  $self->SUPER::find_file($package,@inc);
  }

sub parse_file
  {
  # parse a file for "package A; use B;" and then add "A => B" into $graph
  my ($self, $file) = @_;
 
  $self->output ("  In parse_file($file)\n");

  $self->SUPER::parse_file($file);
  }

sub add_package
  {
  my ($self, $package_name, $version) = @_;

  $self->output ("  In add_package($package_name " . ($version || '') . ")\n");

  $self->SUPER::add_package($package_name, $version);
  }

sub add_link
  {
  my ($self, $src, $dst, $link) = @_;

  $self->output ("  In add_link($src,$dst,$link)\n");

  $self->SUPER::add_link($src,$dst,$link);
  }

sub set_package_version
  {
  my ($self, $src, $ver) = @_;

  $self->output ("  In set_package_version($src,$ver)\n");

  $self->SUPER::set_package_version($src,$ver);
  }

#############################################################################
# hooks that are called through the process of generating the graph. Can be
# overridden in a subclass.

sub hook_after_graph_generation
  {
  my $self = shift;

  $self->output ("  In hook_after_graph_generation()\n");
  }

sub hook_before_colorize
  {
  my $self = shift;

  $self->output ("  In hook_before_colorize()\n");
  }
 
sub hook_after_colorize
  {
  my $self = shift;

  $self->output ("  In hook_after_colorize()\n");
  }
 
1;

__END__

=pod

=head1 NAME

Graph::Usage - generate graph with usage patterns from Perl packages

=head1 SYNOPSIS

	./gen_graph --inc=lib/ --format=graphviz --output=usage_graph
	./gen_graph --nocolor --inc=lib --format=ascii
	./gen_graph --recurse=Graph::Easy
	./gen_graph --recurse=Graph::Easy --format=graphviz --ext=svg
	./gen_graph --recurse=var --format=graphviz --ext=jpg
	./gen_graph --recurse=Math::BigInt --skip='^[a-z]+\z'
	./gen_graph --use=Graph::Usage::MySubClass --recurse=Math::BigInt

Options:

	--color=X		0: uncolored output
				1: default, colorize nodes on how much packages they use
				2: colorize nodes on how much packages use them
	--nocolor		Sets color to 0 (like --color=0, no color at all)

	--inc=path[,path2,..]	Path to source tree or a single file
				if not specified, @INC from Perl will be used
	--recurse=p[,p2,..]	recursively track all packages from package "p"
	--skip=regexp		Skip packages that match the given regexp. Example:
				  -skip='^[a-z]+\z'		skip all pragmas
				  -skip='^Math::BigInt\z'	skip only Math::BigInt
				  -skip='^Math'			skip all Math packages

	--output		Base-name of the output file, default "usage".
	--format		The output format, default "graphviz", valid are:
				  ascii (via Graph::Easy)
				  html (via Graph::Easy)
				  svg (via Graph:Easy)
				  dot (via Graph:Easy)
				  graphviz (see --generator below)
	--generator		Feed the graphviz output to this program, default "dot".
				It must be installed and in your path.
	--extension		Extension of the output file. For "graphviz" it will
				change the format of the output to produce the appr.
				file type.  For all other formats it will merely set
				the filename extension. It defaults to:
				  Format	Extension
				  ascii		txt
				  html		html
				  svg		svg
				  dot		dot
				  graphviz	png
	--flow			The output flows into this direction. Default "south".
				Possible are:
				  north
				  west
				  east
				  south
	--versions		include package version number in graph nodes.

	--debug			print some timing and statistics info.

	--use=Package		Use this package instead of Graph::Usage to do
				the work behind the scenes. See SUBCLASSING.

Help and version:

	--help			print this help and exit
	--version		print version and exit


=head1 DESCRIPTION

This script traces the usage of Perl packages by other Perl packages from
C<use> and C<require> statements and plots the result as a graph.

Due to the nature of the parsing it might miss a few connections, or even
generate wrong positives. However, the goal is to provide a map of what
packages your module/package I<really> uses. This can be quite different
from what the dependency-tree in Makefile.PL states.

=head1 SUBCLASSING

Section not written yet.

General code flow:

	new()
	generate_graph()
		create Graph::Easy object
		call hook_after_graph_generation()
		process files, calling:
			parse_file()
			add_package()
			add_link
		call hook_before_colorize()
		optional: call colorize()
		call hook_after_colorize()
	statistic()
	output_file()
		
=head1 METHODS

=head2 new()

=head2 output()

=head2 generate_graph()

=head2 parse_file()

=head2 statistic()

=head2 colorize()

=head2 color_mapping()

=head2 add_link()

	$brain->add_link('Foo::Bar', 'Foo::Baz', LINK_USE);
	$brain->add_link('Foo::Bar', 'Foo::Baz', LINK_REQUIRE);

=head2 add_package()

=head2 hook_after_graph_generation()

=head2 hook_before_colorize()

=head2 hook_after_colorize()

=head1 TODO

=head2 Output formats

Formats rendered via Graph::Easy (HTML, ASCII and SVG) have a few limitations
and only work good for small to medium sized graphs.

The output format C<graphviz> is rendered via C<dot> or other programs and can
have arbitrary large graphs.

However, for entire source trees like the complete Perl source, the output becomes
unlegible and cramped even when using C<dot>.

I hope I can improve this in time.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL version 2.
See the LICENSE file for information.

=head1 AUTHOR

(c) 2005 by Tels bloodgate.com.

=cut

