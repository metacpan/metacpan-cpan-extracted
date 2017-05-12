package Data::TreeDumper::Renderer::Marpa;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Tree::DAG_Node;

my($previous_level) = - 1;

my($current_node);
my(%node_per_level);

our $VERSION = '1.09';

#-------------------------------------------------

sub begin
{
	my($title, $td_address, $element, $perl_size, $perl_address, $setup) = @_ ;

	return '';

} # End of begin.

#-------------------------------------------------

sub end
{
	my($setup) = @_;

	return '';

} # End of end.

#-------------------------------------------------

sub GetRenderer
{
	return
	({
		BEGIN => \&begin,
		NODE  => \&node,
		END   => \&end,
	});

} # End of Getrenderer.

#-------------------------------------------------

sub node
{
	my($element, $level, $is_terminal, $previous_level_separator, $separator, $element_name,
		$element_value, $td_address, $address_link, $perl_size, $perl_address, $setup) = @_ ;
	$element = '' if (! defined $element); # In case it's undef.

	if (0)
	{
		print "element:                  $element. \n";
		print "level:                    $level. \n";
		print "is_terminal:              $is_terminal. \n";
		print "previous_level_separator: $previous_level_separator. \n";
		print "separator:                $separator. \n";
		print "element_name:             $element_name. \n";
		print "element_value:            $element_value. \n";
		print "td_address:               $td_address. \n";
		print "address_link:             $address_link. \n";
		print "perl_size:                $perl_size. \n";
		print "perl_address:             $perl_address. \n";
		print "setup:                    $setup. \n";
	}

	my($token);
	my($type);

	if ($element =~ /$$setup{RENDERER}{package}\:\:(.+)=/)
	{
		$token = $1;
		$type  = 'Marpa';
	}
	elsif ($element_value =~ /^\d+$/)
	{
		$token = $element_value;
		$type  = 'Marpa';
	}
	else
	{
		$token = $element;
		$type  = 'Grammar';
	}

	my($new_node) = Tree::DAG_Node -> new
	({
		attributes => {type => $type},
		name       => $token,
	});

	# This test works for the very first call because the initial value of $previous_level is < 0.
	# Also, $current_node is unchanged by this 'if' when $level == $previous_level.

	if ($level > $previous_level)
	{
		$current_node = $level == 0 ? $$setup{RENDERER}{root} : $node_per_level{$previous_level};
	}
	elsif ($level < $previous_level)
	{
		$current_node = $level == 0 ? $$setup{RENDERER}{root} : $node_per_level{$level - 1};
	}

	$current_node -> add_daughter($new_node);

	$node_per_level{$level} = $new_node;
	$previous_level         = $level;

	return '';

} # End of node.

#-------------------------------------------------

1;

=pod

=head1 NAME

C<Data::TreeDumper::Renderer::Marpa> - A Marpa::R2 plugin for Data::TreeDumper

=head1 Synopsis

No synopsis needed since this module is used automatically by L<MarpaX::Grammar::Parser>.

=head1 Description

This module is a plugin for L<Data::TreeDumper>. It is used by L<MarpaX::Grammar::Parser> during the parsing
of a L<Marpa::R2>-style BNF.

Users do not need to call any of the functions in this module, and it has no methods.

=head1 Installation

This module is installed automatically when you install L<MarpaX::Grammar::Parser>.

=head1 Methods

This class has no methods, only functions as per the design of L<Data::TreeDumper>.

=head2 begin()

This is called before the traversal of the data structure starts.

=head2 end()

This is called after the last node has been processed.

=head2 GetRenderer()

This is called by L<Data::TreeDumper> to initialize the plugin.

=head2 node()

This is called for each node in the data structure.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Grammar::Parser>.

=head1 Author

L<MarpaX::Grammar::Parser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Home page: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
