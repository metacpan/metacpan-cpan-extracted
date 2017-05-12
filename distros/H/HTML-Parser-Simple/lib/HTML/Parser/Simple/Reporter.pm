package HTML::Parser::Simple::Reporter;

use strict;
use warnings;

use HTML::Parser::Simple::Attributes;

use Moo;

extends 'HTML::Parser::Simple';

our $VERSION = '2.02';

# -----------------------------------------------

sub traverse
{
	my($self, $node, $output, $depth) = @_;
	$depth        ||= 0;
	my(@child)    = $node -> getAllChildren;
	my($metadata) = $node -> getNodeValue;
	my($content)  = $$metadata{content};
	my($name)     = $$metadata{name};

	# We ignore the root, which means we ignore the DOCTYPE.

	if ($name ne 'root')
	{
		my($s) = ('  ' x ($depth - 1) ) . "$name. Attributes: ";
		my($p) = HTML::Parser::Simple::Attributes -> new;
		my($a) = $p -> parse($$metadata{attributes});
		$s     .= $p -> hashref2string($a) . '. Content:';
		my($c) = '';

		for my $index (0 .. $#child + 1)
		{
			$c .= $index <= $#$content && defined($$content[$index]) ? $$content[$index] : '';
		}

		$c =~ s/^\s+//;
		$c =~ s/\s+$//;
		$s .= " $c" if (length $c);

		push @$output, $s;
	}

	for my $index (0 .. $#child)
	{
		$self -> traverse($child[$index], $output, $depth + 1);
	}

} # End of traverse.

# -----------------------------------------------

sub traverse_file
{
	my($self, $input_file_name) = @_;
	$input_file_name  ||= $self -> input_file;

	$self -> input_file($input_file_name);
	$self -> log("Reading $input_file_name");

	open(INX, $input_file_name) || Carp::croak "Can't open($input_file_name): $!";
	my($html);
	read(INX, $html, -s INX);
	close INX;

	Carp::croak "Can't read($input_file_name): $!" if (! defined $html);

	$self -> log('Parsing');

	$self -> parse($html);

	$self -> log('Traversing');

	my($output) = [];

	$self -> traverse($self -> root, $output, 0);

	return $output;

} # End of traverse_file.

# -----------------------------------------------

1;

=head1 NAME

HTML::Parser::Simple::Reporter - A sub-class of HTML::Parser::Simple

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use HTML::Parser::Simple::Reporter;

	# -------------------------

	# Method 1:

	my($p) = HTML::Parser::Simple::Reporter -> new(input_file => 'data/s.1.html');
	my($s) = $p -> traverse_file;

	print "$_\n" for @$s;

	# Method 2:

	my($p) = HTML::Parser::Simple::Reporter -> new;
	my($s) = $p -> traverse_file(input_file => 'data/s.1.html');

	print "$_\n" for @$s;

See scripts/traverse.file.pl.

=head1 Description

C<HTML::Parser::Simple::Reporter> is a pure Perl module.

It is a sub-class of L<HTML::Parser::Simple>.

Specifically, this module overrides the method L<HTML::Parse::Simple/traverse($node)>, to demonstrate
a different way of formatting the output.

It parses HTML V 4 files, and generates a tree of nodes, with 1 node per HTML tag.

The data associated with each node is documented in the L<HTML::Parse::Simple/FAQ>.

See also L<HTML::Parser::Simple> and L<HTML::Parser::Simple::Attributes>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<HTML::Parser::Simple::Reporter>.

This is the class contructor.

Usage: C<< HTML::Parser::Simple::Reporter -> new() >>.

This method takes a hashref of options.

Call C<new()> as C<< new({option_1 => value_1, option_2 => value_2, ...}) >>.

Available options (each one of which is also a method):

=over 4

=item o None specific to this class

=back

But since this class is a sub-class of L<HTML::Parser::Simple>, it share all the options to
C<< new() >> documented in that class: L<HTML::Parser::Simple/Constructor and initialization>.

=head1 Methods

This module is a sub-class of L<HTML::Parser::Simple>, and inherits all its methods.

Further, it overrides the L<HTML::Parser::Simple/traverse($node)> method.

=head2 traverse($node, $output, $depth)

Returns $output as an arrayref of strings.

Traverses the tree built by calling L<HTML::Parser::Simple/parse($html)>.

Parameters:

=over 4

=item o $node

The node at which to start the traversal. This is normally $self -> root.

=item o $output

The arrayref in which output is stored. It is normally used like this:

	my($arrayref) = [];

	$p -> traverse($p -> root, $arrayref);

	print "$_\n" for @$arrayref;

=item o $depth

The depth of $node within the tree. This is normally set to 0.

In C<< traverse() >> it is used to indent the output.

If not specified, it defaults to 0.

=back

Lastly note that this method ignores the root of the tree, and hence ignores the DOCTYPE which is stored
as an attribute of the root.

=head2 traverse_file($input_file_name)

Returns an arrayref of formatted text generated from the nodes in the tree built by calling
L<HTML::Parse::Simple/parse($html)>.

Traverses the given file, or the file named in C<< new(input_file => $name) >>, or the file named in
C<< input_file($name) >>.

Basically it does this (recalling that this class sub-classes L<HTML::Parser::Simple>):

	# Read file and store contents in $html.

	$self -> parse($html);

	my($output) = [];

	$self -> traverse($self -> root, $output, 0);

	return $output;

However, since this class has overridden the L<HTML::Parse::Simple/traverse($node)> method, the output is
not written anywhere, but rather is stored in an arrayref, and returned as the result of this method.

Note: The parameter passed in to C<< traverse_file($input_file_name) >>, takes precedence over the
I<input_file> parameter passed in to C<< new() >>, and over the internal value set with
C<< input_file($in_file_name) >>.

Lastly, the parameter passed in to C<< traverse_file($input_file_name) >> is used to update
the internal value set with the I<input_file> parameter passed in to C<< new() >>,
or set with a call to C<< input_file($in_file_name) >>.

See the L</Synopsis> for sample code. See also scripts/traverse.file.pl.

=head1 FAQ

See L<HTML::Parse::Simple/FAQ>.

=head1 Author

C<HTML::Parser::Simple> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2009 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
