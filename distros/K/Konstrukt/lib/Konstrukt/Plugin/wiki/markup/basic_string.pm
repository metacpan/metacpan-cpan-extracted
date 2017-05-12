=head1 NAME

Konstrukt::Plugin::wiki::markup::basic_string - Inline plugin to handle basic markup (without templates)

=head1 SYNOPSIS
	
	my $b = use_plugin 'wiki::markup::basic';
	my $rv = $b->process($tag);

=head1 DESCRIPTION

This one will handle all basic text formatting markup and substitute it
with html-markup.

=head1 EXAMPLE

	*strong*
	/empathized/
	_underlined_
	-deleted-
	+inserted+
	^superscript^
	~subscript~
	#code#

=cut

package Konstrukt::Plugin::wiki::markup::basic_string;

use strict;
use warnings;

use Konstrukt::Parser::Node;
use base 'Konstrukt::Plugin::wiki::markup::inlineplugin';

=head1 METHODS

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
	
	my $markup_config = '*|<strong>|</strong>,/|<em>|</em>,_|<u>|</u>,-|<del>|</del>,+|<ins>|</ins>,^|<sup>|</sup>,~|<sub>|</sub>,#|<code>|</code>';
	
	my $markup;
	my $count;
	foreach my $tag (split /,/, $markup_config) {
		my ($symbol, $open, $close) = split /\|/, $tag;
		$markup->{$symbol} = [$open, $close];
		$count->{$symbol} = 0;
	}
	
	
#	#the markup will be mapped like this:
#	my $markup = {
#		'*' => ['<strong>', '</strong>'],
#		'/' => ['<em>',     '</em>'],
#		'_' => ['<u>',      '</u>'],
#		'-' => ['<del>',    '</del>'],
#		'+' => ['<ins>',    '</ins>'],
#		'^' => ['<sup>',    '</sup>'],
#		'~' => ['<sub>',    '</sub>'],
#		'#' => ['<code>',   '</code>'],
#	};
#	
#	#count the opened markup tags
#	my $count = {
#		'*' => 0,
#		'/' => 0,
#		'_' => 0,
#		'-' => 0,
#		'+' => 0,
#		'^' => 0,
#		'~' => 0,
#		'#' => 0,
#	};
	
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
				if ($token =~ /[$splitter]/o) {
					#may this token be an opening token?
					if ($maybe_open) {
						#the next character must not be a whitespace
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
						$token_type = 'open' if defined $next_text and $next_text =~ /^\S/;
					} else {
						#can only close a tag, that's been opened
						$token_type = 'close' if $count->{$token} > 0;
					}
				}
				#what to do?
				if ($token_type eq 'open' or $token_type eq 'close') {
					#add markup
					$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => $markup->{$token}->[$token_type eq 'open' ? 0 : 1] }));
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
			$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => $markup->{$token}->[1] }));
		}
	}
	
	#now delete all the old nodes...
	$nodes->{first_child} = $nodes->{last_child} = undef; #dirty hack...
	#... and add the new nodes
	$node = $container->{first_child};
	while (defined $node) {
		my $next_node = $node->{next};
		$nodes->add_child($node);
		$node = $next_node;
	}
	
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
