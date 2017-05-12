#TODO: execute_again really not needed?
#FEATURE: perl-interface to create if-nodes

=head1 NAME

Konstrukt::Plugin::if - Conditional blocks

=head1 SYNOPSIS
	
B<Usage:>

	<!-- will put out "elsif1" -->
	<& if condition="0" &>
		<$ then $>then<$ / $>
		<$ elsif condition="1" $>elsif1<$ / $>
		<$ elsif condition="1" $>elsif2<$ / $>
		<$ else $>else<$ / $>
	<& / &>

	<!-- shortcut, when only using "then" and no elsif or else -->
	<!-- will put out "The condition is true!" -->
	<& if condition="2 > 1" &>
		The condition is true!
	<& / &>
	
	<!-- dynamic conditions -->
	<!-- non-dynamic conditions will only be checked once and then get cached -->
	<& if condition="int rand 2" dynamic="1" &>
		The condition is true with a chance of 50%!
	<& / &>

B<Result:>

	<!-- will put out "elsif1" -->
	elsif1
	
	<!-- shortcut, when only using "then" and no elsif or else -->
	<!-- will put out "The condition is true!" -->
		The condition is true!

	<!-- dynamic conditions -->
	<!-- non-dynamic conditions will only be checked once and then get cached -->
		The condition is true with a chance of 50%!

=head1 DESCRIPTION

Will put out the appropriate content for the conditions. Will delete the block,
if no condition matches and no else block is supplied.

The condition will be C<eval>'ed. So if you only want to check if a value is
true, you might want to encapsulate it in quotes, so that it won't be interpreted
as perl code:

	<& if condition="'some value'" &>true<& / &>

Of course this will lead into problems, when the data between the quotes contains
qoutes itself. So you really should be careful with the values that are put into
the condition, as they will be executed as perl code. You'd better never pass conditions,
that contain any strings entered by a user.

As for the L<perl plugin|Konstrukt::Plugin::perl/DESCRIPTION> you can use these variables
in your condition code: $L<Konstrukt::Handler>, $L<Konstrukt::Settings>,
$L<Konstrukt::Lib>, $L<Konstrukt::Debug>, $L<Konstrukt::File>, $template_values.

=head2 Static vs. dynamic conditions

Usually all conditions will be assumed static. That is that the result of the
evaluation of the condition will be the same for every request. Thus
the condition will only be evaluated once and then the result will be cached for
later usage. 

But as the conditions actually are only executed perl code, they may also be
dynamic. Consider:

	<& if condition="int rand 2" dynamic="1" &>
		The condition is true with a chance of 50%!
	<& / &>

The definition of the condition is static (it's only text), but the result may
vary on every request. So you have to define the C<dynamic> attribute, which
will prevent the caching of the result and evaluate the condition on every
request.

So in the common case, wher you just use template values as the condition,
there is no need to set the dynamic attribute. But when you execute perl code
in the condition, it is likely that you want the dynamic behaviour.

=cut

package Konstrukt::Plugin::if;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

use Konstrukt::Parser::Node;
use Konstrukt::Debug;

=head1 METHODS

=head2 prepare

Parse for <$ then $> and so on.

If it's not a dynamic condition, it can already be processed in the prepare run.

If the if-tag is preliminary (i.e. when there is a tag inside the tag) this method
will be called in the execute run nevertheless.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare { 
	my ($self, $tag) = @_;

	#parse for <$ then $>, <$ elsif $> and <$ else $>
	my $actions = { '$' => undef };
	my $prepared = $Konstrukt::Parser->prepare($tag, $actions);
	
	#extract then, elsif and else
	my ($then, @elsif, $else);
	my $node = $prepared->{first_child};
	while (defined $node) {
		if ($node->{type} eq 'tag' and $node->{handler_type} eq '$') {
			if ($node->{tag}->{type} eq 'then') {
				if (defined $then) {
					$Konstrukt::Debug->debug_message("Skipping <\$ then \$> because of double definition.") if Konstrukt::Debug::NOTICE;
				} else {
					$then = $node;
				}
			} elsif ($node->{tag}->{type} eq 'elsif') {
				push @elsif, $node;
			} elsif ($node->{tag}->{type} eq 'else') {
				if (defined $else) {
					$Konstrukt::Debug->debug_message("Skipping <\$ else \$> because of double definition.") if Konstrukt::Debug::NOTICE;
				} else {
					$else = $node;
				}
			}
		}
		$node = $node->{next};
	}
	
	#use tag content if no <$ then $> has been specified
	$then = $tag unless defined $then;
	
	#save then, elsif, else
	$tag->{then}   = $then;
	$tag->{elsifs} = \@elsif;
	$tag->{else}   = $else;
	
	#replace the else tag by the appropriate result, unless its a dynamic condition
	if ($tag->{tag}->{attributes}->{dynamic}) {
		#don't do anything now. process it in the execute run.
		$tag->{dynamic} = 1;
		return undef;
	} else {
		return $self->execute($tag);
	}
}
#= /prepare


=head2 execute

Evaluate the condition and return the appropriate result.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute { 
	my ($self, $tag) = @_;

	#decide which block to use.
	#this can be done in the prepare-method, as this method will just be called
	#when the tag is fully parsed, thus not preliminary and so we've got the condition.
	#actually the prepare-method will be called in the execute run, when the tag
	#was preliminary in the prepare run.
	my $template_values = $tag->{template_values};
	if (defined $tag->{tag}->{attributes}->{condition} and eval $tag->{tag}->{attributes}->{condition}) {
		#return the tag, that will be replaced by its children
		return $tag->{then};
	} else {
		#process elsifs
		foreach my $node (@{$tag->{elsifs}}) {
			if (defined $node->{tag}->{attributes}->{condition} and eval $node->{tag}->{attributes}->{condition}) {
				#return the elsif node, that will be replaced by its children
				return $node;
			}
		}
		#return the else node, that will be replaced by its children
		return $tag->{else} if defined $tag->{else};
		#return an empty node, that will be deleted.
		return Konstrukt::Parser::Node->new();
	}
}
#= /execute

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut
