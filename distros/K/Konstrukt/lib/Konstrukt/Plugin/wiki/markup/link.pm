#FEATURE: nested links
#         [[image:foo|image of [[something else]].]]
#         [[some article|[[image:http://foo.bar/baz.jpg]]]]
#FEATURE: anchors

=head1 NAME

Konstrukt::Plugin::wiki::markup::link - Inline plugin to handle links

=head1 SYNOPSIS
	
	my $l = use_plugin 'wiki::markup::link';
	my $rv = $l->process($tag);

=head1 DESCRIPTION

This one will look for (internal and external, implicit and explicit) links
and converts them into HTML-links.

=head1 CONFIGURATION

You may define a list of link plugins that will handle the different link types.
The first plugin that matches a link will handle it. So the list should be sorted
by descending specificity.

The defaults are:

	wiki/link/plugins nolink image file external wiki
	
Note that the wiki plugin should be the last one in the chain since it acts like
a catchall plugin ans will match B<all> explicit links.

=head1 EXAMPLE

Implicit links

	CamelCase or SomePage
	
	http://foo.bar/baz
	
	!NoLink
	
Explicit links

	Explicit links are required here [[nocamelcase]] or here [[NoSpaceAroundLink]].
	
	[[SomePage|But with some other description]]
	
	[[http://foo.bar/baz|somthing here]]

=cut

package Konstrukt::Plugin::wiki::markup::link;

use strict;
use warnings;

use Konstrukt::Debug;

use base 'Konstrukt::Plugin::wiki::markup::inlineplugin';
use Konstrukt::Plugin; #import use_plugin

=head1 METHODS

=head2 init

Initialization.

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default('wiki/link/plugins', 'nolink image file external article');
	
	return 1;
}
#= /init

=head2 process

This method will do the work. Will look for new links inside the text and will
also check if the target of existing wiki links exists or not.

B<Parameters>:

=over

=item * $nodes - Container node (of type L<Konstrukt::Parser::Node>) containing
all (text-)nodes of this documents.

=back

=cut
sub process {
	my ($self, $nodes) = @_;
	
	#we have plugins for several kinds of links.
	#load them and generate a list that allows us to find out the plugin
	#responsible for a specific kind of links.
	my @plugins;
	my @link_plugins = map { use_plugin "wiki::markup::link::$_" } split /\s+/, $Konstrukt::Settings->get('wiki/link/plugins');
	#create a pattern that checks if a word is an implicit link
	my $is_implicit_link = '(';
	foreach my $plugin (@link_plugins) {
		#get the regexp that will match the links for this plugin
		my ($imatch, $xmatch) = $plugin->matching_regexps();
		#add this regexp and the plugin into the list
		push @plugins, [$imatch, $xmatch, $plugin];
		$is_implicit_link .= "$imatch|";
	}
	$is_implicit_link = substr($is_implicit_link, 0, length($is_implicit_link) - 1) . ')';
	
	#container to collect the nodes. the type is arbitrary
	my $container = Konstrukt::Parser::Node->new({ type => 'wikinodecontainer' });
	
	#split all nodes into tokens.
	#we will save the link string of an explicit link in this variable
	my $link_string;
	my $node = $nodes->{first_child};
	while (defined $node) {
		#save next node since $node->{next} might get overwritten
		#when moving this node around in the tree.
		my $next_node = $node->{next};
		if (not $node->{wiki_finished} and $node->{type} eq 'plaintext') {
			#split at explicit link boundaries and into words
			my @tokens = split /(\[\[|\]\]|\s+)/, $node->{content};
			foreach my $token (@tokens) {
				if (defined $link_string) {
					#we had an explicit link start before.
					if ($token eq ']]') {
						#explicit link end.
						#find the responsible plugin
						my $matching_plugin = $self->_find_matching_plugin(\@plugins, $link_string, 'explicit');
						if (defined $matching_plugin) {
							#handle link
							my $result = $matching_plugin->handle($link_string);
							$container->add_child($result);
							$result->replace_by_children();
						} else {
							#no plugin is responsible for this link. add as plaintext
							$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 0, type => 'plaintext', content => "[[$link_string]]"}));
						}
						#reset link string
						$link_string = undef;
					} else {
						#add to the link string
						$link_string .= $token;
					}
				} elsif ($token eq '[[') {
					#starting explicit link
					$link_string = '';
				} else {
					if ($token =~ /$is_implicit_link/ and defined (my $matching_plugin = $self->_find_matching_plugin(\@plugins, $token, 'implicit'))) {
						#implicit link found!
						my $result = $matching_plugin->handle($token);
						$container->add_child($result);
						$result->replace_by_children();
					} else {
						#just plaintext
						$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 0, type => 'plaintext', content => $token}));
					}
				}
			}
		} else {
			#ignored node
			$container->add_child($node);
		}
		$node = $next_node;
	}
	
	#check if there is an unclosed explicit link
	if (defined $link_string) {
		#just add as plaintext.
		$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 0, type => 'plaintext', content => "[[$link_string"}));
	}
	
	#now move all the nodes from the "working container" to the "output countainer"
	$nodes->{first_child} = $nodes->{last_child} = undef; #dirty hack...
	$container->move_children($nodes);
	
	return 1;
}
# /process

=head2 _find_matching_plugin

Will return the plugin responsible for a given link string or undef if no
plugin matches.

Will only be used internally.

B<Parameters>:

=over

=item * $plugins - Reference to an array containing arrayreferences each
containing a matching regexp and the plugin.

=item * $link - The link string

=item * $type - Will be 'explicit' or 'implicit'. Determines the type of regexps
to use to match the string.

=back

=cut
sub _find_matching_plugin {
	my ($self, $plugins, $link, $type) = @_;
	
	if ($type eq 'implicit') {
		$type = 0;
	} elsif ($type eq 'explicit') {
		$type = 1;
	} else {
		$Konstrukt::Debug->error_message("\$type must be 'implicit' or 'explicit'") if Konstrukt::Debug::ERROR;
		return undef;
	}
	
	my $matching_plugin;
	foreach my $plugin (@{$plugins}) {
		if (defined $plugin->[$type] and $link =~ /$plugin->[$type]/) {
			$matching_plugin = $plugin->[2];
			last;
		}
	}
	
	return $matching_plugin;
}
# /_find_matching_plugin

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut
