#TODO: parse again?
#FEATURE: use Safe; ?
#FEATURE: compile?
# http://search.cpan.org/author/INGY/Module-Compile-0.15/lib/Module/Compile.pm
# http://groups.google.de/group/de.comp.lang.perl.misc/browse_thread/thread/5b6fb02b0883e529/6f6d09cdcbb92925?lnk=st&q=Perl-Code+w%C3%A4hrend+der+Laufzeit+kompilieren%2Feval()+vorkompilieren&rnum=1#6f6d09cdcbb92925
# http://search.cpan.org/~nwclark/perl-5.8.6/ext/B/B/Bytecode.pm
# my $compiled = `perl -MO=Bytecode,-H -e 'print "hi!\n"`;
#
# use ByteLoader 0.05;
# <byte code>

=head1 NAME

Konstrukt::Plugin::perl - Embedding perl code in your pages/templates

=head1 SYNOPSIS
	
B<Usage:>

	<& perl &>print "foo"<& / &>

B<Result:>

	foo
	
=head1 DESCRIPTION

With this plugin you may embed Perl code into the source code of an Konstrukt-webpage.

Those variables will be available to your code: $L<Konstrukt::Handler>, $L<Konstrukt::Settings>,
$L<Konstrukt::Lib>, $L<Konstrukt::Debug>, $L<Konstrukt::File>, $template_values.

The variable C<$template_values> contains the template values passed to the file, which
contains the perl tag. It can be used to produce output for these values.
The structure of this data will look like described in L<Konstrukt::Plugin::template/node>.
The values may be scalars (strings) or L<Konstrukt::Parser::Node>s. You should B<not>
modify this data!

Note that it would be wise in some cases to enclose the perl code within a comment
to prevent parsing of the perl code by the Konstrukt-parser:

	<& perl &>
		#<--
		sub one { return 1; }
		if (0<&one()) { print "hi!"; }
		#-->
	<& / &>

Otherwise C<0E<lt>&one()> would lead into incorrect parsing as C<E<lt>&> would get
recognized as a plugin tag start.

For more general information about plugins take a look at L<Konstrukt::Plugin>.

=head1 CONFIGURATION

You may configure the perl plugin to parse the printed output for new tags:
	
	#per default the output won't be parsed again
	perl/parse_output_for_tags 0

=cut

package Konstrukt::Plugin::perl;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Debug;
use Konstrukt::Parser::Node;

=head1 METHODS

=head2 init

Initialization. Will only be used internally.

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("perl/parse_output_for_tags", 0);
	
	return 1;
}
#= /init

=head2 prepare_again

The executed perl code B<may> generate plaintext that will be parsed to new tag
nodes.

If you plan to do it (although it is better to directly push the according tag
nodes), you have to set the setting perl/parse_output_for_tags to 1.

=cut
sub prepare_again {
	return $Konstrukt::Settings->get('perl/parse_output_for_tags');
}
#= /prepare_again

=head2 execute_again

Yes, this plugin will very likely generate new tags.

=cut
sub execute_again {
	return 1;
}
#= /execute_again

=head2 prepare

We cannot prepare anything as the perl code generally will be completely dynamic.

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	#Don't do anything beside setting the dynamic-flag
	$tag->{dynamic} = 1;#TODO: neccessary? could be detected by the parser!
	
	return undef;
}
#= /prepare

=head2 execute

All the work is done in the execute step.
The result of C<print>-statements will be put into the page at the position
of the perl-tag.

=cut
sub execute {
	my ($self, $tag) = @_;
	
	#collect the comment and plaintext nodes that will be executed
	my $code = "#line 1 \"perl block @ " . $Konstrukt::File->relative_path($Konstrukt::File->current_file()) . "\"\n";
	my $node = $tag->{first_child};
	while (defined $node) {
		if ($node->{type} eq 'plaintext' or $node->{type} eq 'comment') {
			$code .= $node->{content};
		}
		$node = $node->{next};
	}
	
	#reset the dummy node to collect the output, activate print redirection, register for print events
	$self->reset_nodes();
	$Konstrukt::PrintRedirector->activate();
	$Konstrukt::Event->register("Konstrukt::PrintRedirector::print", $self, \&print_event);
	
	#access to template fields:
	my $template_values = $tag->{template_values};
	
	#execute the perl block
	eval $code;
	
	#check for errors
	if (Konstrukt::Debug::ERROR and $@) {
		#Errors in eval
		my $errors = $@;
		chomp $errors;
		$Konstrukt::Debug->error_message("Error while executing embedded perl!\n$errors");
		$self->add_node("[ERROR: Error while executing embedded perl! $errors" . "]");
	}
	
	#deactivate print redirection, deregister for print events
	$Konstrukt::PrintRedirector->deactivate();
	$Konstrukt::Event->deregister_all_by_object("Konstrukt::PrintRedirector::print", $self);
	
	return $self->get_nodes();
}
#= /execute

=head2 print_event

Accepts the C<printredirector_print>-event and adds a plaintext node

B<Parameters>:

=over

=item * @data - The data passed to the print function

=back

=cut
sub print_event {
	my ($self, @data) = @_;
	
	if (defined $self->{collector_node}->{last_child} and $self->{collector_node}->{last_child}->{type} eq 'plaintext') {
		$self->{collector_node}->{last_child}->{content} .= join('', @data);
	} else {
		$self->add_node(join '', @data);
	}
	
	return 1;
}

return 1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut

