=head1 NAME

Konstrukt::Plugin::diff - Print out an XHTML table with the difference between two texts

=head1 SYNOPSIS

B<Usage:>

 	<& diff &>
		<$ left $>
		1
		2
		3
		<$ / $>
		<$ right $>
		1
		3
		<$ / $>
	<& / &>

or

	<!-- set another amount of "context" lines -->
	<& diff context="2" &>
		...
	<& / &>

or

	<!-- define a header for the columns -->
	<& diff left_header="text a" right_header="text b" &>
		...
	<& / &>
	
B<Result:>

A table showing the difference between the two texts.

=head1 DESCRIPTION

With this plugin you compare two texts and put out the difference as an XHTML table.

You may also use its Perl interface:

	my $diff = use_plugin 'diff';
	my $html = $diff->diff("1\n2\n3", "1\n3");

=head1 CONFIGURATION
	
You may configure the default behaviour of the diff plugin:

	#context: number of (equal) lines around a diff hunk
	diff/context 1048576

=cut

package Konstrukt::Plugin::diff;

use strict;
use warnings;

use Konstrukt::Debug;
use Konstrukt::Parser::Node;
use Text::Diff ();

use base qw/Konstrukt::Plugin Text::Diff::Base/; #inheritance


=head1 METHODS

=head2 init

Initialization.

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("diff/context", 1048576);
	
	return 1;
}
#= /init

=head2 prepare

We can do the work already in the prepare run if there is only static content
inside the tag.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	unless ($tag->{dynamic}) {
		return $self->process($tag);
	} else {
		#don't do anything. process it in the execute run
		return undef;
	}
}
#= /prepare

=head2 execute

Now finally generate the result, if not already done in the prepare run.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;
	return $self->process($tag);
}
#= /execute

=head2 process

The real work is done here.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub process {
	my ($self, $tag) = @_;

	#parse for <$ left $> and <$ right $>
	my $actions = { '$' => undef };
	my $prepared = $Konstrukt::Parser->prepare($tag, $actions);
	
	#extract left and right text
	my ($left, $right);
	my $node = $prepared->{first_child};
	while (defined $node) {
		if ($node->{type} eq 'tag' and $node->{handler_type} eq '$' and ($node->{tag}->{type} eq 'left' or $node->{tag}->{type} eq 'right')) {
			#collect plaintext
			my $plaintext = '';
			my $ptnode = $node->{first_child};
			while (defined $ptnode) {
				$plaintext .= $ptnode->{content} if $ptnode->{type} eq 'plaintext';
				$ptnode = $ptnode->{next};
			}
			if ($node->{tag}->{type} eq 'left') {
				$left = $plaintext;
			} else {
				$right = $plaintext;
			}
		}
		$node = $node->{next};
	}
	
	#compute and return result
	$self->reset_nodes();
	if (defined $left and defined $right) {
		$self->add_node($self->diff($left, $right, $tag->{tag}->{attributes}->{left_header}, $tag->{tag}->{attributes}->{right_header}, $tag->{tag}->{attributes}->{context}));
	} else {
		$Konstrukt::Debug->error_message("Left or right or both texts missing! Cannot diff!") if Konstrukt::Debug::ERROR;
	}
	
	return $self->get_nodes();
}
#= /process

=head2 diff

Generates the XHTML-Tables.

B<Parameters>

=over

=item * $left - The left text.

=item * $right - The right text.

=item * $left_header - The left column header. If undef, no header will be displayed.

=item * $right_header - The right column header. If undef, no header will be displayed.

=item * $context - Optional: The number of context lines around a diff hunk

=back

=cut
sub diff {
	my ($self, $left, $right, $left_header, $right_header, $context) = @_;
	
	$context ||= $Konstrukt::Settings->get('diff/context');
	$self->{left_header}  = $left_header;
	$self->{right_header} = $right_header;
	return Text::Diff::diff(\$left, \$right, { STYLE => __PACKAGE__, CONTEXT => $context});
}
#= /diff

=head2 file_header

Generates the header of the whole diff.

Will be called by L<Text::Diff>.

=cut
sub file_header {
	my $result = "<table class=\"diff\">\n";
	if ($Konstrukt::Plugin::diff->{left_header} or $Konstrukt::Plugin::diff->{left_header}) {
		$result .= "<tr><th class=\"diff_header\" colspan=\"2\">" . ($Konstrukt::Plugin::diff->{left_header} || '') . "</th><th class=\"diff_header\" colspan=\"2\">" . ($Konstrukt::Plugin::diff->{right_header} || '') . "</th></tr>\n";
	}
	return $result;
}
#= /file_header

=head2 hunk_header

Generates the header of each hunk.

Will be called by L<Text::Diff>.

=cut
sub hunk_header {
	return "";
}
#= /hunk_header

=head2 hunk

Generates the table rows for each hunk.

Will be called by L<Text::Diff>.

=cut
sub hunk {
	my ($self, $left, $right, $diff, $info) = @_;
	
	my $result;
	#iterate over each line
	for (my $i = 0; $i < @{$diff}; $i++) {
		my ($left_index, $right_index, $operation) = @{$diff->[$i]};
		
		my @actions;
		if ($operation eq ' ') {
			#identical line
			@actions = qw/= =/;
		} elsif ($operation eq '+') {
			#new line on the right side
			$left_index = -1;
			@actions = qw/_ +/;
		} else {#$operation eq '-'
			#line removed on the left side
			#replaced by another line?
			if (@{$diff} > $i + 1 and $diff->[$i + 1]->[2] eq '+') {
				#replaced
				$right_index = $diff->[++$i]->[1];
				@actions = qw/- +/;
			} else {
				#just a removed line
				$right_index = -1;
				@actions = qw/- _/;
			}
		}
		#left and right text
		my $left_text  = ($left_index  == -1 ? '' : $left->[$left_index]  );
		my $right_text = ($right_index == -1 ? '' : $right->[$right_index]);
		#escape HTML meta characters and remove trailing newline. set to &nbsp; if empty
		map { $_ = $Konstrukt::Lib->html_escape($_); $_ =~ s/\s*$//; $_ = '&nbsp;' if not length($_); } ($left_text, $right_text);
		#line numbers
		my $left_line  = ($left_index  == -1 ? '&nbsp;' : $left_index  + $info->{OFFSET_A});
		my $right_line = ($right_index == -1 ? '&nbsp;' : $right_index + $info->{OFFSET_B});
		#conversion of actions to CSS classes
		my $action_to_class = { '=' => 'diff_equal', '+' => 'diff_add', '-' => 'diff_remove', '_' => 'diff_empty' };
		#print row
		$result .= "<tr><td class=\"$action_to_class->{$actions[0]}_number\">$left_line</td><td class=\"$action_to_class->{$actions[0]}\">$left_text</td><td class=\"$action_to_class->{$actions[1]}_number\">$right_line</td><td class=\"$action_to_class->{$actions[1]}\">$right_text</td></tr>\n";
	}
	
	return $result;
}
#= /hunk

=head2 hunk_footer

Generates the footer of each hunk.

Will be called by L<Text::Diff>.

=cut
sub hunk_footer {
	return "<tr><td class=\"diff_seperator\" colspan=\"4\">&nbsp;</td></tr>\n";
}
#= /hunk_footer

=head2 file_footer

Generates the footer of the whole diff.

Will be called by L<Text::Diff>.

=cut
sub file_footer {
	return "</table>\n";
}
#= /file_footer

return 1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut

