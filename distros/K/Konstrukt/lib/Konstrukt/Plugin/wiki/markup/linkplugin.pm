=head1 NAME

Konstrukt::Plugin::wiki::markup::linkplugin - Base class for plugins to handle links

=head1 SYNOPSIS

Creating your own plugin:

	use base 'Konstrukt::Plugin::wiki::markup::linkplugin';
	#overwrite the methods

Using a link plugin:

	my $l = use_plugin 'wiki::markup::link::yourplugin';
	
	#get the regexps that will match the links for which this plugin is
	#responsible for
	my ($match_implicit, $match_explicit) = $l->matching_regexp();
	
	#let the plugin handle a link string.
	#the plugin returns a container node which contains the nodes that
	#will replace the link string.
	my $replacement = $l->handle($link_string);

=head1 DESCRIPTION

This is the base class for all link-markup plugins. There exist several plugins
for different kinds of links and you may crerate your own ones.

=head1 EXAMPLE

Look at the actual link plugins for examples.

=cut

package Konstrukt::Plugin::wiki::markup::linkplugin;

use strict;
use warnings;

=head1 METHODS

=head2 new

Constructor of this class.

=cut
sub new {
	my ($class) = @_;
	return bless {}, $class;
}
#= /new

=head2 init

Initialization. May be overwriten by your class. Your class should set its
default settings here.

=cut
sub init {
	my ($self) = @_;
	#set default settings
	#$Konstrukt::Settings->set("wiki/foo", 'bar') unless defined $Konstrukt::Settings->get("wiki/foo");
	return 1;
}
#= /init

=head2 install

Installation of your plugin. For example you may want to create template files
for your markup here.

For more information take a look at the documentation at L<Konstrukt::Plugin/install>.

B<Parameters:>

none

=cut
sub install {
	return 1;
}
# /install

=head2 matching_regexps()

This method will return two regexp's that will match the link strings for which
this plugin is responsible for.

The first regexp will match all implicit links that this plugin can handle.
The second one will match all explicit links that this plugin can handle.
Those will be the same in most cases, but there are also links that will only
match when they are explicit links.

If you don't want your plugin to match, return undef for each regexp.

Internally the text will be split into words and each word will be matched
against the regexps of your plugin. If it matches, your plugin will
L</handle> this link. This implies that implicit links cannot contain whitespaces.

Note: This also implies that a text consisting of 1000 words in combination with 5
link plugins will lead into ~7000 regexp-operations in the worst case. In the best
case we would have ~2000 matches. But actually I cannot make it simpler as I
don't know any other way to match the beginning of a word (\b will match \W\w
and not \s\S). Thank god that we've got caching...

=cut
sub matching_regexps {
	return ();
}
# /matching_regexps

=head2 handle()

This method will handle the link string and return a container node containing
the nodes that will replace the link string.

B<Parameters>:

=over

=item * $link - The link string.

=back

=cut
sub handle {
	return Konstrukt::Parser::Node->new({ type => 'wikinodecontainer' });
}
# /handle

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut
