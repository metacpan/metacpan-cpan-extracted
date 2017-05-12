#TODO: (parse_again): no prepare on plugins with dynamic flag?
#TODO: prepare_again: maybe option to skip parsing of plaintext nodes?
#TODO: dynamic-field necessary? a node should be "dynamic" when there still is a tag-node left after the prepare run
#      -> dynamic-field just saves the work to detect if there are tag-nodes left
#      -> generate this field automatically?!
#TODO: Full documentation of the parsing process
#TODO: error messages on syntax errors
#TODO: wrong tag "<&>" won't be detected as error

=head1 NAME

Konstrukt::Parser - Parser for the tag syntax

=head1 SYNOPSIS

	#this will be done in your top-level handler.
	use Konstrukt::Parser;
	
	#prepare run
	my $actions = { '&' => $Konstrukt::TagHandler::Plugin };
	my $prepared = $Konstrukt::Parser->prepare(\$some_input, $actions);
	
	#execute run
	my $executed = $Konstrukt::Parser->execute($prepared, $actions);

=head1 DESCRIPTION

Parses a given file against special (e.g. <&...&>) tags.

=head1 CONFIGURATION

	#all tag names will be lowercased
	parser/lowercase_tags 1
	parser/tag_start      <
	parser/tag_end        >
	parser/comment_start  <!--
	parser/comment_end    -->
	
=cut

package Konstrukt::Parser;

use strict;
use warnings;

use Konstrukt::Parser::Node;
use Konstrukt::Debug;

BEGIN {
	require Data::Dump if Konstrukt::Debug::DEBUG;
}

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

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("parser/lowercase_tags", 1);
	$Konstrukt::Settings->default("parser/tag_start",      '<');
	$Konstrukt::Settings->default("parser/tag_end",        '>');
	$Konstrukt::Settings->default("parser/comment_start",  '<!--');
	$Konstrukt::Settings->default("parser/comment_end",    '-->');
	
	return 1;
}
#= /init

=head2 prepare

This sub will accept a scalarref or a node with some children.

Plaintext nodes will be parsed into tags and executed.

All plugins/tags that return static output on static input will be executed
($plugin->prepare()) and replaced by the returned static content.

Plugins/tags that generate dynamic content will stay in the tree to be executed
in the L</execute> run ($plugin->execute()).

Tag nodes will be prepare()'d recursively.

B<Parameters>:

=over

=item * $input - Reference to a scalar (plaintext) or a node
(Konstrukt::Parser::Node) with some plaintext nodes.

=item * $actions - Hashreference containing the tag-types (as hash-keys) that
are recognized and the handler object (see also L<Konstrukt::TagHandlers> that
should handle this tag-type.
Should look like
	$actions = {
		'&' => $Konstrukt::TagHandler::Plugin,
		...
	}

Currently only used by the template plugin.

=back

=cut
sub prepare {
	my ($self, $input, $actions) = @_;

	#create root node
	my $root;
	if (ref($input) eq "Konstrukt::Parser::Node") {
		$root = $input;
	} else {
		$root = Konstrukt::Parser::Node->new({ type => 'root' });
	}
	
	#normalize input to (tag node)->[children]
	if (ref($input) eq 'SCALAR') {
		$root->add_child(Konstrukt::Parser::Node->new({ type => "plaintext", content => $$input }));
	} elsif (ref($input) ne "Konstrukt::Parser::Node") {
		$Konstrukt::Debug->debug_message("Passed input is no arrayref and no Konstrukt::Parser::Node!") if Konstrukt::Debug::ERROR;
		return;
	}
	
	#tag syntax
	my $comment_start = $Konstrukt::Settings->get('parser/comment_start');
	my $comment_end   = $Konstrukt::Settings->get('parser/comment_end');
	my $tag_start     = $Konstrukt::Settings->get('parser/tag_start');
	my $tag_end       = $Konstrukt::Settings->get('parser/tag_end');
	
	#generate split-regexp and regexp to detect tags
	my @split_delimiters = ($comment_start, $comment_end);
	my @tag_starts;
	my @tag_ends;
	foreach my $key (keys %{$actions}) {
		#reverse key
		my $yek = reverse $key;
		my $start = $tag_start . $key;
		my $end   = $yek . $tag_end;
		#escape meta characters:
		$start =~ s/([\+\?\*\$\@\(\)\[\]\{\}\|\\])/\\$1/g;
		$end   =~ s/([\+\?\*\$\@\(\)\[\]\{\}\|\\])/\\$1/g;
		push @split_delimiters, ($start, $end);
		push @tag_starts, $start;
		push @tag_ends, $end;
	}
	my $split_regexp    = "(".join("|", @split_delimiters).")";
	my $tagstart_regexp = "\\A(".join("|", @tag_starts).")";
	my $tagend_regexp   = "(".join("|", @tag_ends).")\\Z";
	
	#save the current node and the parent node under which new nodes should be added
	my $node = $root->{first_child};
	my $parent = $root;
	
	#append a dummy node at the end to let us know when we are finished
	$root->add_child(Konstrukt::Parser::Node->new({ type => 'dummy' }));
	
	#iterate over all passed nodes
	while (defined($node)) {
		#split plaintext nodes into tokens
		#only analyze plaintext nodes and replace the nodes with a list of nodes as the result of the analysis
		if ($node->{type} eq 'plaintext') {
			$Konstrukt::Debug->debug_message(">>> Current plaintext node to parse:\n$node->{content}") if Konstrukt::Debug::DEBUG;
			#split this node into tokens, remove this node.
			my @tokens = split /$split_regexp/s, $node->{content};
			my $old_node = $node;
			$node = $node->{next};
			$old_node->delete();
			#analyze all tokens
			for (my $current_token = 0; $current_token < @tokens; $current_token++) {
				#skip empty tokens:
				next if !length($tokens[$current_token]);
				$Konstrukt::Debug->debug_message("---> current token: |$tokens[$current_token]|\n") if Konstrukt::Debug::DEBUG;
				#$Konstrukt::Debug->debug_message("-> PRE processing\n".$root->tree_to_string()."\n") if Konstrukt::Debug::DEBUG;
				my $tag; #will be used under some conditions
				if ($tokens[$current_token] eq $comment_start) {
					#comment: join all tokens up to the comment's end into one comment node
					$Konstrukt::Debug->debug_message("!!! comment\n") if Konstrukt::Debug::DEBUG;
					my $comment;
					while ($tokens[$current_token] ne $comment_end) {
						$comment .= $tokens[$current_token++];
					}
					$comment .= $tokens[$current_token];
					#append to existing comment node or push new node
					if (defined($parent->{last_child}) and $parent->{last_child}->{type} eq 'comment') {
						#append
						$parent->{last_child}->{content} .= $comment;
					} else {
						#push comment node as new child
						$parent->add_child(Konstrukt::Parser::Node->new({ type => 'comment', content => $comment }));
					}
				} elsif ($tokens[$current_token] =~ /$tagstart_regexp/) {
					$Konstrukt::Debug->debug_message("!!! tagstart\n") if Konstrukt::Debug::DEBUG;
					my $tag_type = substr($tokens[$current_token], 1);
					#tag start: create preliminary tag, jump behind this node
					$tag = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => $tag_type });
					$tag->{content} = Konstrukt::Parser::Node->new({ type => 'tagcontent', preliminary => 1, parent => $tag });
					$parent->add_child($tag);
					#collect all following tokens as childs inside the tag's "content" until an appropriate tag end is found.
					$parent = $tag->{content};
				} elsif ($tokens[$current_token] =~ /$tagend_regexp/) {
					$Konstrukt::Debug->debug_message("!!! tagend\n") if Konstrukt::Debug::DEBUG;
					my $tag_type = reverse(substr($tokens[$current_token], 0, length($tokens[$current_token]) - 1));
					#tag end: if the tag's content is static (completely parsed/executed),
					#we can parse the tag's content and save the result (type, attributes, ...) for this tag.
					unless ($parent->{dynamic}) {
						#prepare the tag
						#$parent points to the preliminary tag content.
						#$parent->{parent} points to the preliminary tag.
						#parse_and_prepare_tag() will return the new parent node.
						$parent = $self->parse_and_prepare_tag($parent->{parent}, $actions);
					} else {
						#tag end found. we cannot finally parse this tag, because inside this tag there is dynamic content.
						#jump up in the tree. the tag is above the tag's content.
						$tag = $parent->{parent};
						#check for single closing tag
						my $last_text = $parent->{last_child};
						if (defined $last_text and $last_text->{type} eq 'plaintext' and $last_text->{content} =~ /\/\s*\z/o) {
							#if it is a single closing tag, new nodes will be collected after this tag.
							$parent = $tag->{parent};
						} else {
							#if the preliminary tag is an opening tag, new nodes will be collected below this tag.
							$parent = $tag;
						}
					}
				} else {
					$Konstrukt::Debug->debug_message("!!! plaintext\n") if Konstrukt::Debug::DEBUG;
					#plaintext between the tag delimiters. push plaintext node as new child
					$parent->add_child(Konstrukt::Parser::Node->new({ type => 'plaintext', content => $tokens[$current_token] }));
				}
				$Konstrukt::Debug->debug_message("-> POST processing\n".$root->tree_to_string()."\n") if Konstrukt::Debug::DEBUG;
			}#end for each token
		} elsif ($node->{type} eq 'dummy') {
			#dummy node found. delete it and stop the processing
			$Konstrukt::Debug->debug_message("!!! dummy found. delete. stop\n") if Konstrukt::Debug::DEBUG;
			$node->delete();
			$node = undef;
		} else {
			#move node to the end.
			my $next_node = $node->{next};
			$node->delete();
			$parent->add_child($node);
			if ($node->{type} eq 'tag') {
				#recursively run prepare on this tag and it's children if it's not yet
				#marked as dynamic.
				$Konstrukt::Debug->debug_message("-> Tag node.\n") if Konstrukt::Debug::DEBUG;
				if (not $node->{dynamic}) {
					#recurse if there are children
					$Konstrukt::Debug->debug_message("---> start recursion\n") if Konstrukt::Debug::DEBUG and defined $node->{first_child};
					$self->prepare($node, $actions) if defined $node->{first_child};
					$Konstrukt::Debug->debug_message("<--- end recursion\n") if Konstrukt::Debug::DEBUG and defined $node->{first_child};
					#run prepare() on this tag if there are still no dynamic children
					$self->prepare_tag($node, $actions) unless $node->{dynamic};
				} else {
					#parent inherits dynamic flag
					$node->{parent}->{dynamic} ||= $node->{dynamic};
				}
				$Konstrukt::Debug->debug_message("-> POST reprepare tag\n".$root->tree_to_string()."\n") if Konstrukt::Debug::DEBUG;
			} else {
				$Konstrukt::Debug->debug_message("No plaintext and no tag node: $node->{type}. Skipping\n") if Konstrukt::Debug::DEBUG;
				$Konstrukt::Debug->debug_message("-> POST skipping\n".$root->tree_to_string()."\n") if Konstrukt::Debug::DEBUG;
			}
			#proceed
			$node = $next_node;
		}#end if node eq plaintext
	}#end for each passed node
	
	#clean up: merge neighbouring plaintext/comment nodes of same type
	$self->merge_similar_neighbours($root);
	
	return $root;
}
#= /prepare

=head2 parse_and_prepare_tag

Will generate a final tag of the passed preliminary tag. The prepare method
will be called on this tag.

Returns the new "parent" node, under which all new nodes will be collected.

B<Parameters>:

=over

=item * $node - The preliminary Tag.

=item * $actions - Hashreference containing the tag-types (as hash-keys) that
are recognized and the handler object (see also L<Konstrukt::TagHandlers> that
should handle this tag-type.

Should look like:

	$actions = {
		'&' => $Konstrukt::TagHandler::Plugin,
		...
	}

=back

=cut
sub parse_and_prepare_tag {
	my ($self, $tag, $actions) = @_;

	#static content. join plaintext content nodes into one string and parse it.
	my $tag_content = '';
	my $tag_node = $tag->{content}->{first_child};
	while (defined $tag_node) {
		if ($tag_node->{type} eq 'plaintext') {
			$tag_content .= $tag_node->{content};
		}
		$tag_node = $tag_node->{next};
	}

	#parse the tag
	$tag->{tag} = $self->parse_tag($tag_content);
	#delete the now parsed content
	delete $tag->{content};
	#execute the tag
	if ($tag->{tag}->{closing} or $tag->{tag}->{singleclosing}) {
		#closing tag (e.g. <& / &>) or single closing tag (e.g. <& template / &>):
		#jump up to the parent and execute the funtion that is assigned to the tag
		if ($tag->{tag}->{closing}) {
			#remove that closing tag (<& / &>) as we don't need it.
			#it only says us to go one level up in the tree.
			my $opening_tag = $tag->{parent};
			if (Konstrukt::Debug::ERROR and not exists $opening_tag->{content}->{preliminary} and (not defined $opening_tag or $opening_tag->{type} ne 'tag')) {
				#no according opening tag
				$Konstrukt::Debug->error_message("Closing tag of type $tag->{handler_type} without appropriate opening tag!", 1);
			}
			$tag->delete();
			#now we will work with the opening tag
			$tag = $opening_tag;
		}
		#let the plugin generate its result for this tag
		$self->prepare_tag($tag, $actions);
		#jump above the tag. all following nodes will be siblings of this tag.
		return $tag->{parent};
	} else {
		#opening tag (e.g. <& template &>) found.
		#all following nodes will be child nodes of this tag now:
		return $tag;
	}
}
#= /parse_and_prepare_tag

=head2 prepare_tag

Will run the prepare method on a specified tag, if possible (i.e. if the tag
could be finally parsed, an action is specified and the tag doesn't have
dynamic children).

The result will be put into the tree instead of the prepared tag, if the tag
returned a result.

B<Parameters>:

=over

=item * $tag - The tag to prepare.

=item * $actions - Hashreference containing the tag-types (as hash-keys) that
are recognized and the handler object (see also L<Konstrukt::TagHandlers> that
should handle this tag-type.

Should look like:

	$actions = {
		'&' => $Konstrukt::TagHandler::Plugin,
		...
	}

=back

=cut
sub prepare_tag {
	my ($self, $tag, $actions) = @_;
	
	$Konstrukt::Debug->debug_message("///// preparing tag type $tag->{tag}->{type}") if Konstrukt::Debug::DEBUG;
	
	my $tag_type = $tag->{handler_type};
	#only prepare finally parsed tags
	if (not exists $tag->{content}->{preliminary}) {
		if (exists $actions->{$tag_type} and defined $actions->{$tag_type}) {
			#prepare tag
			my $result = $actions->{$tag_type}->prepare($tag);
			#prepare the result again if the plugin may generate new tags nodes
			if ($actions->{$tag_type}->prepare_again($tag)) {
				$Konstrukt::Debug->debug_message(">>>> PREPARE AGAIN! $tag_type") if Konstrukt::Debug::DEBUG;
				$result = $self->prepare($result, $actions);
			}
			#merge the result into the tree
			$self->merge_plugin_results($tag, $result);
		} else {
			#we don't know how to handle this tag type.
			#leave the tag in the tree. it will be processed later.
			#set the dynamic content flag
			$tag->{parent}->{dynamic} = $tag->{dynamic} = 1;
			
			#the parent tag inherits the dynamic content flag
			$tag->{parent}->{dynamic} ||= $tag->{dynamic};
			$Konstrukt::Debug->debug_message("No action specified for tag type '$tag_type'!") if Konstrukt::Debug::DEBUG;
		}
	} else {
		#leave the tag in the tree. it will be processed later. set the dynamic content flag
		$tag->{parent}->{dynamic} = $tag->{dynamic} = 1;
		$Konstrukt::Debug->debug_message("Won't prepare preliminary tag '$tag_type' !") if Konstrukt::Debug::DEBUG;
	}
	
	return 1;
}
# /prepare_tag

=head2 execute

This sub takes a tree (usually the result of L</prepare>) and executes all plugins.
Every plugin B<must> return static content now as the result of the execution
is the final result of the parsing process.

B<Parameters>:

=over

=item * $node - Reference to a node of the tree. Usually you will pass the
root node, which is the result of L</prepare>.

=item * $actions - Hashreference containing the tag-types (as hash-keys) that
are recognized and the handler object (see also L<Konstrukt::TagHandlers> that
should handle this tag-type.
Should look like
	$actions = {
		'&' => $Konstrukt::TagHandler::Plugin,
		...
	}

=item * $executionstage - Optional: Only tags whose stage is <= the execution
stage will be executed. This parameter will only be set internally. You should
B<never> set it on your own when calling the execute method.

=back

=cut
sub execute {
	my ($self, $tag, $actions, $executionstage) = @_;
	
	if (defined $executionstage) {
		$Konstrukt::Debug->debug_message("---> RECURSION\n") if Konstrukt::Debug::DEBUG;
		
		#recursively iterate over all children and execute the tags of this stage
		my $node = $tag->{first_child};
		while (defined $node) {
			if ($node->{type} eq 'tag') {
				#handle preliminary tags
				$self->execute($node->{content}, $actions, $executionstage)
					if exists $node->{content}->{preliminary};
				#execute tag
				$self->execute($node, $actions, $executionstage);
			}
			$node = $node->{next};
		}
		
		#all children will be now be static, if their execution stages have been reached.
		#otherwise there are still tags left and we cannot execute this node.
		if (defined $tag->{type} and $tag->{type} eq 'tag') {
			
			#update the current path/file, in which this tag has been
			$Konstrukt::File->push($tag->{template_path}) if exists $tag->{template_path};
			
			#create final a tag of a preliminary tag, if the children
			#already have been executed.
			if (exists $tag->{content}->{preliminary}) {
				if (($tag->{content}->{executionstage} || 0) <= $executionstage) {
					#preliminary tag whose content has become static.
					#parse and prepare the tag. it will be executed below.
					$Konstrukt::Debug->debug_message("---> PARSE AND PREPARE $tag->{handler_type}\n") if Konstrukt::Debug::DEBUG;
					$self->parse_and_prepare_tag($tag, $actions);
					#the tag has been prepared, if it was a singleclosing tag.
					#if we've had an opening preliminary tag, we have to prepare it now, as parse_and_prepare_tag didn't do this.
					unless ($tag->{tag}->{singleclosing}) {
						my $result = $actions->{$tag->{handler_type}}->prepare($tag);
						#merge the result into the tree
						$self->merge_plugin_results($tag, $result);
					}
					#check if the tag has been removed in the prepare run.
					#if so, we don't have to run the execute method on it.
					unless ($tag eq $tag->{parent}->{first_child} or defined $tag->{prev}->{next} and $tag->{prev}->{next} eq $tag) {
						#tag has been replaced
						$Konstrukt::Debug->debug_message("---> tag $tag->{handler_type} $tag->{tag}->{type} has been replaced in the prepare-method during the execute run\n") if Konstrukt::Debug::DEBUG;
						return;
					}
				} else {
					#preliminary tag, whose children haven't been executed yet.
					#the tag must inherit the execution stage of the tags which are
					#inside this tag, so that it only gets (parsed and) executed after those tags.
					$tag->{executionstage} = $tag->{content}->{executionstage}
						if ($tag->{executionstage} || 0) < $tag->{content}->{executionstage};
				}
			}
			
			#let the plugin generate its result for this tag
			$Konstrukt::Debug->debug_message("---> PRE exec\n".$tag->tree_to_string()."\n") if Konstrukt::Debug::DEBUG;
			if (defined($actions->{$tag->{handler_type}})) {
				#determine execution stage of this tag. adjust the max execution stages.
				my $tag_exec_stage = $tag->{tag}->{attributes}->{executionstage} || $actions->{$tag->{handler_type}}->executionstage($tag) || 1;
				$tag->{executionstage} = $tag_exec_stage
					if ($tag->{executionstage} || 0) < $tag_exec_stage;
				#execute the tag if its stage has been reached
				if ($tag->{executionstage} <= $executionstage) {
					$Konstrukt::Debug->debug_message(">>>>> EXECUTING $tag->{handler_type} $tag->{tag}->{type}\n".$tag->tree_to_string()."\n") if Konstrukt::Debug::DEBUG;
					my $result = $actions->{$tag->{handler_type}}->execute($tag);
					#prepare and execute the result again if the plugin may generate new tags
					if ($actions->{$tag->{handler_type}}->prepare_again($tag)) {
						$Konstrukt::Debug->debug_message(">>>> PREPARE AGAIN! $tag->{handler_type}") if Konstrukt::Debug::DEBUG;
						$result = $self->prepare($result, $actions);
					}
					if ($actions->{$tag->{handler_type}}->execute_again($tag)) {
						$Konstrukt::Debug->debug_message(">>>> EXECUTE AGAIN! $tag->{handler_type}") if Konstrukt::Debug::DEBUG;
						$result = $self->execute($result, $actions, $executionstage);
					}
					#merge the result into the tree
					$self->merge_plugin_results($tag, $result);
				} else {
					#must be executed later
					$Konstrukt::Debug->debug_message("Execution stage $tag->{executionstage} not yet reached for tag " . ($tag->{handler_type} || "(undefined handler type)") . " " . ($tag->{tag}->{type} || "(undefined tag type)") . "!") if Konstrukt::Debug::DEBUG;
					#parent must inherit this execution stage as it cannot be executed
					#before the children have been executed!
					$tag->{parent}->{executionstage} = $tag->{executionstage}
						if ($tag->{parent}->{executionstage} || 0) < $tag->{executionstage};
					#update the next stage counter to the least next stage
					$self->{next_stage} = $tag->{executionstage}
						if ($self->{next_stage} || 999_999_999) > $tag->{executionstage};
				}
			} else {
				$Konstrukt::Debug->debug_message("No action specified for tag type '$tag->{handler_type}'!") if Konstrukt::Debug::DEBUG;
			}
			
			#pop the current path/file, in which this tag has been
			$Konstrukt::File->pop() if exists $tag->{template_path};
			
			$Konstrukt::Debug->debug_message("---> POST exec\n") if Konstrukt::Debug::DEBUG;
		}
	} else {
		#the tags/plugins may define an execution stage for themselves to allow
		#an execution order that differs from the order of the tags in the page.
		#iterate over all execution stages and recursively execute all tags for each stage.
		my $executionstage = 1;
		do {
			$Konstrukt::Debug->debug_message("=== EXECUTION STAGE: $executionstage ========\n\nTree before execution of this stage:\n\n" . $tag->tree_to_string() . "\n===============================\n") if Konstrukt::Debug::DEBUG;
			$self->{next_stage} = undef; #reset next stage counter
			$self->execute($tag, $actions, $executionstage);
			$executionstage = $self->{next_stage};
		} until (not defined $self->{next_stage});
	}
	
	return $tag;
}
#= /execute

=head2 merge_plugin_results

Only used internally by L</prepare> and L</execute>.
Will merge the result returned by a plugin into the current position of the tree.

B<Parameters>:

=over

=item * $tag - The tag which generated/modified the result.

=item * $result - The result returned by a plugin.

=back

=cut
#merge the results returned by a plugin into the tree
sub merge_plugin_results {
	my ($self, $tag, $result) = @_;
	
	$Konstrukt::Debug->debug_message("merging") if Konstrukt::Debug::DEBUG;
	
	#the handler may return a scalar or an Konstrukt::Parser::Node.
	#the handler may also modify the passed tree itself and return undef.
	if (defined($result)) {
		if (ref($result) eq 'SCALAR') {
			#dereference the scalar
			$result = $$result;
		}
		if (not ref $result) {
			#convert scalar to a node containing of plaintext node
			my $plaintextnode = Konstrukt::Parser::Node->new({ type => 'plaintext', content => $result });
			$result = Konstrukt::Parser::Node->new();
			$result->add_child($plaintextnode);
		}
		if (ref($result) ne "Konstrukt::Parser::Node") {
			#invalid result
			$Konstrukt::Debug->error_message("Invalid result returned by the handler for tag $tag->{tag}->{type}") if Konstrukt::Debug::ERROR;
			$tag->delete();
		}
		#replace the tag with with the children of $result
		if (defined $result->{first_child}) {
			$tag->replace_by_node($result);
			$result->replace_by_children();
		} else {
			#no result. just delete the tag
			$tag->delete();
		}
	} else {
		#the tag's subtree has been autonomousliy modified by the handler/plugin.
		#the parent tag inherits the dynamic content flag
		$tag->{parent}->{dynamic} ||= $tag->{dynamic};
	}
}
#= /merge_plugin_results

=head2 merge_similar_neighbours

Only used internally by L</prepare>.
Will recursively merge neighbouring plaintext or comment nodes of the same type.

B<Parameters>:

=over

=item * $start - The node whose children should be processed

=back

=cut
sub merge_similar_neighbours {
	my ($self, $start) = @_;
	
	my $node = $start->{first_child};
	while (defined $node) {
		if (defined $node->{next} and $node->{type} eq $node->{next}->{type} and ($node->{type} eq "plaintext" or $node->{type} eq "comment")) {
			#merge nodes
			$node->{content} .= $node->{next}->{content};
			$node->{next}->delete();
		} elsif ($node->{type} eq "tag") {
			#recursion
			$self->merge_similar_neighbours($node) if defined $node->{first_child};
			$node = $node->{next};
		} else {
			$node = $node->{next};
		}
	}
}
#= /merge_similar_neighbours

=head2 parse_tag

Accepts a tag-string (e.g. C<template src="blah.template">) and returns the parsed tag
as an hashreference.

B<Parameters>:

=over

=item * $tagstring - The tag string

=back

=head3 Returns:

The parsed tag as an hashreference. Example for C<template src="blah.template" />

	$tag = {
		type => 'template',
		attributes => { src => 'blah.template' },
		singleclosing => 1
	}

=cut
sub parse_tag {
	my ($self, $tagstring) = @_;
	
	my $lc = $Konstrukt::Settings->get('parser/lowercase_tags');
	my $tag;
	
	$Konstrukt::Debug->debug_message(">>>> parse_tag: tagstring $tagstring\n") if Konstrukt::Debug::DEBUG;
	
	#cut off any leading and tailing whitespaces
	$tagstring =~ s/^\s+//g;
	$tagstring =~ s/\s+$//g;
	
	#check for closing tag
	if (substr($tagstring,0,1) eq '/') {
		$tag->{'closing'} = 1;
		#cut leading "/" and whitespaces
		$tagstring = substr($tagstring,1);
		$tagstring =~ s/^\s+//g;
	}
	
	#check for single closing tag
	if (substr($tagstring,-1,1) eq '/') {
		$tag->{'singleclosing'} = 1;
		#cut tailing "/" and whitespaces
		$tagstring = substr($tagstring,0,length($tagstring)-1);
		$tagstring =~ s/\s+$//g;
	}
	
	#ensure that there are no whitespaces around the = symbols:
	$tagstring =~ s/\s+=\s+/=/g;
	
	#is there any content left?
	if (length($tagstring) > 0) {
		#the first "word" must be the tag's type. it may be the only word.
		$tagstring =~ /^(\S*)/;
		$tag->{type} = ($lc ? lc($1) : $1);
		#strip it
		$tagstring = substr($tagstring,length($1));
		
		#the rest of the string must consist of attributes.
		#allowed syntax:
		# attribute=value
		# attribute="value with spaces"
		# "attr with spaces"="value"
		# singleton_attr_without_value
		my @tokens = split /([="']|\s+)/, $tagstring;
		my $state = 0; #0: get attribute name, 1: get value
		my $last_name; #the last attribute name
		for (my $i = 0; $i < @tokens; $i++) {
			next unless length $tokens[$i]; #skip empty tokens
			if ($tokens[$i] eq "=") {
				#now look for the attribute value.
				$state = 1;
			} elsif ($tokens[$i] =~ /\s+/) {
				#whitespace separating the attributes. ignore.
			} else {
				my $string = ''; #the current string (attribute name or value)
				if ($tokens[$i] eq '"' or $tokens[$i] eq "'") {
					#get next quote delimited string
					my $open_quote = $tokens[$i];
					#eat up all tokens until the next matching quote
					while (++$i < @tokens) {
						last if $tokens[$i] eq $open_quote;
						$string .= $tokens[$i];
					}
					$Konstrukt::Debug->error_message("Invalid tag '$tagstring'! Quote $open_quote not closed.")
						if Konstrukt::Debug::ERROR and ($tokens[$i] || '') ne $open_quote;
				} else {
					#just a plain word.
					$string = $tokens[$i];
				}
				#the string is either an attribute name or a value
				if ($state == 0) {
					#name
					next unless length $string; #skip empty names
					$last_name = $string;
					$tag->{attributes}->{$last_name} = undef;
				} else {
					#value
					$tag->{attributes}->{$last_name} = $string;
					$state = 0;
				}
			}
		}
	}
	
	$Konstrukt::Debug->debug_message(">>>> parse_tag: tag " . Data::Dump::dump($tag)) if Konstrukt::Debug::DEBUG;
	
	return $tag;
}
#= /parse_tag

#create global object
sub BEGIN { $Konstrukt::Parser = __PACKAGE__->new() unless defined $Konstrukt::Parser; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Parser::Node>, L<Konstrukt::TagHandler>, L<Konstrukt>

=cut
