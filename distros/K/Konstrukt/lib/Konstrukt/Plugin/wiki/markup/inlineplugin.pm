=head1 NAME

Konstrukt::Plugin::wiki::markup::inlineplugin - Base class for wiki inline plugins

=head1 SYNOPSIS
	
	use base 'Konstrukt::Plugin::wiki::markup::inlineplugin';
	
	#read the docs

=head1 DESCRIPTION

Its main purpose it the documentation of the creation of custom
wiki inline plugins.

=cut

package Konstrukt::Plugin::wiki::markup::inlineplugin;

use strict;
use warnings;

=head1 METHODS

=head2 new

Constructor of this class

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

=head2 process

This method will do the work of your plugin.

A conainer node containing several child nodes (maybe of type 'plaintext',
maybe not) will be passed to this method. All nodes are L<Konstrukt::Parser::Node>
objects.

Usually you will only work on nodes matching this criteria

	not $node->{wiki_finished} and $node->{type} eq 'plaintext'

as you should leave alone non-plaintext nodes and finally parsed nodes.

You might want to implement some sort of token based parsing. The text will very
likely be splitted into several (plaintext and non-plaintext) nodes, so you
will not be able to run regular expressions over the whole text. So it would be
a good idea to split the nodes into tokens on which you can decide how to modify
the nodes (alter content, add new nodes, remove existing nodes).

Take a look at the supplied plugins to see how it could work.

The return value of this method will not be recognized.

After your plugin processed the block, its output will be post-processed in the
same way as after L<Konstrukt::Plugin::wiki::blockplugin/process>.

B<Parameters>:

=over

=item * $nodes - Container node (of type L<Konstrukt::Parser::Node>) containing
all (text-)nodes of this documents.

=back

=cut
sub process {
	my ($self, $nodes) = @_;
	
	return 1;
}
# /process

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut
