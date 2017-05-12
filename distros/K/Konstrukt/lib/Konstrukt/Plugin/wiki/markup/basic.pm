=head1 NAME

Konstrukt::Plugin::wiki::markup::basic - Inline plugin to handle basic markup

=head1 SYNOPSIS
	
	my $b = use_plugin 'wiki::markup::basic';
	my $rv = $b->process($tag);

=head1 DESCRIPTION

This one will handle all basic text formatting markup and substitute it
with html-markup.

=head1 EXAMPLE

	*strong*
	_strong2_
	/empathized/
	-deleted-
	+inserted+
	^superscript^
	~subscript~
	`code`

=cut

package Konstrukt::Plugin::wiki::markup::basic;

use strict;
use warnings;

use Konstrukt::Parser::Node;

use base 'Konstrukt::Plugin::wiki::markup::inlineplugin';
use Konstrukt::Plugin; #import use_plugin

=head1 METHODS

=head2 init

Initialization.

=cut
sub init {
	my ($self) = @_;
	
	#path
	$self->{template_path} = $Konstrukt::Settings->get("wiki/template_path");
}
#= /init

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($self->{template_path});
}
# /install

=head2 process

This method will do the work.

B<Parameters>:

=over

=item * $nodes - Container node (of type L<Konstrukt::Parser::Node>) containing
all (text-)nodes of this documents.

=back

=cut
sub process {
	my ($self, $nodes) = @_;

	#get a plugin-object
	my $template = use_plugin 'template';
	
	#the markup will be mapped like this:
	my $markup = {
		'*' => 'strong.template',
		'_' => 'strong2.template',
		'/' => 'em.template',
		'-' => 'del.template',
		'+' => 'add.template',
		'^' => 'sup.template',
		'~' => 'sub.template',
		'`' => 'code.template'
	};
	
	#count the opened markup tags
	my $count = {
		'*' => 0,
		'_' => 0,
		'/' => 0,
		'-' => 0,
		'+' => 0,
		'^' => 0,
		'~' => 0,
		'`' => 0,
	};
	
	#we will split the text into tokens separated by the markup characters:
	my $splitter = join '', keys %{$markup};
	#escape
	$splitter =~ s/(\W)/\\$1/gi;
	
	#container to collect the nodes. the type is arbitrary
	my $container = Konstrukt::Parser::Node->new({ type => 'wikinodecontainer' });
	
	#split all nodes into tokens.
	#we will save if the next markup token can be an opening or closing token,
	#which is the case when the character before the token is a whitespace or a token.
	my $maybe_open = 1;
	my $node = $nodes->{first_child};
	while (defined $node) {
		#save next node since $node->{next} might get overwritten
		#when moving this node around in the tree.
		my $next_node = $node->{next};
		if (not $node->{wiki_finished} and $node->{type} eq 'plaintext') {
			my @tokens = split /([$splitter])/o, $node->{content};
			for (my $i = 0; $i < @tokens; $i++) {
				my $token = $tokens[$i];
				#skip empty tokens
				next unless length $token;
				#of what type is this token? opening, closing or plaintext?
				my $token_type = 'plaintext';
				#determine type of this token
				#warn $token;
				if ($token =~ /[$splitter]/o) {
					#may this token be an opening token?
					if ($maybe_open) {
						#the next character must not be a whitespace (and not the same token)
						my $next_text;
						#look for a following token
						my $t = $i + 1;
						while ($t < @tokens) {
							if (length $tokens[$t]) {
								#found!
								$next_text = $tokens[$t];
								last;
							}
							$t++;
						}
						$next_text = $next_node->{content} if not defined $next_text and defined $next_node and not $next_node->{wiki_finished} and $next_node->{type} eq 'plaintext';
						#$token_type = 'open' if defined $next_text and $next_text =~ /^\S/;
						$token_type = 'open' if defined $next_text and $next_text =~ /^\S/ and substr($next_text, 0, length($token)) ne $token;
					} else {
						#can only close a tag, that's been opened
						$token_type = 'close' if $count->{$token} > 0;
					}
				}
				#what to do?
				if ($token_type eq 'open' or $token_type eq 'close') {
					#add template node
					if ($token_type eq 'open') {
						my $template_node = $template->node($self->{template_path} . "markup/" . $markup->{$token});
						my $new_container = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '$', tag => { type => 'content' }});
						$template_node->add_child($new_container);
						$container->add_child($template_node);
						#collect nodes inside the new container node
						$container = $new_container;
					} else {
						#go one level up
						$container = $container->{parent}->{parent};
					}
					#$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => $markup->{$token}->[$token_type eq 'open' ? 0 : 1] }));
					#count opening/closing markup
					$count->{$token} += $token_type eq 'open' ? 1 : -1;
				} else {
					#plaintext
					$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 0, type => 'plaintext', content => $token }));
					#may following tokens be opening tokens?
					$maybe_open = ($token =~ /\s$/) ? 1 : 0;
				}
			}
		} else {
			#ignored node
			$container->add_child($node);
		}
		$node = $next_node;
	}
	
	#close unclosed markup
	foreach my $token (keys %{$count}) {
		while ($count->{$token}-- > 0) {
			#$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => $markup->{$token}->[1] }));
			$container = $container->{parent}->{parent};
		}
	}
	
	#now delete all the old nodes...
	$nodes->{first_child} = $nodes->{last_child} = undef; #dirty hack...
	$container->move_children($nodes);
	
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

__DATA__

-- 8< -- textfile: markup/add.template -- >8 --

<nowiki><add class="wiki"></nowiki><+$ content $+><+$ / $+><nowiki></add></nowiki>

-- 8< -- textfile: markup/code.template -- >8 --

<nowiki><code class="wiki"></nowiki><+$ content $+><+$ / $+><nowiki></code></nowiki>

-- 8< -- textfile: markup/del.template -- >8 --

<nowiki><del class="wiki"></nowiki><+$ content $+><+$ / $+><nowiki></del></nowiki>

-- 8< -- textfile: markup/em.template -- >8 --

<nowiki><em class="wiki"></nowiki><+$ content $+><+$ / $+><nowiki></em></nowiki>

-- 8< -- textfile: markup/strong.template -- >8 --

<nowiki><strong class="wiki"></nowiki><+$ content $+><+$ / $+><nowiki></strong></nowiki>

-- 8< -- textfile: markup/strong2.template -- >8 --

<nowiki><strong class="wiki alternate"></nowiki><+$ content $+><+$ / $+><nowiki></strong></nowiki>

-- 8< -- textfile: markup/sub.template -- >8 --

<nowiki><sub class="wiki"></nowiki><+$ content $+><+$ / $+><nowiki></sub></nowiki>

-- 8< -- textfile: markup/sup.template -- >8 --

<nowiki><sup class="wiki"></nowiki><+$ content $+><+$ / $+><nowiki></sup></nowiki>

