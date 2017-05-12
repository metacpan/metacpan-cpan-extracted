=head1 NAME

Konstrukt::SimplePlugin - Base class for simple Konstrukt plugins.

=head1 SYNOPSIS
	
=head2 Writing own plugins
	
	package Konstrukt::Plugin::my_plugin;
	
	use base 'Konstrukt::SimplePlugin';
	
	#(over)write (some of) the methods: init, default-action, other action handlers.
	
	#per request initialization
	sub init {
		my ($self) = @_;
		#...
	}
	
	#initialization that is needed before the first time your plugin can be used
	 
	
	#write methods for your actions (will be called with page.html?${yourpluginname}_action=some_action)
	sub some_action : Action {
		my ($self, $tag, $content, $params) = @_;
		#...
	}
	
	#will be called when no sub matches the action name
	sub default : Action {
		my ($self, $tag, $content, $params) = @_;
		#...
	}
	
	#...
	
	1;

=head2 Using existing plugins (within your plugin)

Basically:

	use Konstrukt::Plugin; #import use_plugin
	
	my $plugin = use_plugin 'some_plugin';
	$plugin->method();

See L<Konstrukt::Plugin/Using existing plugins> for more details.

=head1 DESCRIPTION

Base class for simple Konstrukt plugins.

Only the methods relevant for creating a simple plugin are documented.

Every method that should be accessible from the client must have a C<:Action>
attribute. Otherwise it cannot be called from the client.

If you want some more control over what your plugin does (e.g. to gain
performance) you may want to inherit L<Konstrukt::Plugin>.
As C<SimplePlugin> inherits from C<Plugin> you may also take more control
of your plugin behaviour as you could when developing a C<Plugin>. The methods
aren't documented here to keep it simple, but you may of course read the
L<Plugin|Konstrukt::Plugin> docs and apply (most of) them to your C<SimplePlugin>.

=cut

package Konstrukt::SimplePlugin;

use strict;
use warnings;

use Konstrukt::Debug; #import constants
use Konstrukt::Parser::Node;

use base qw/Konstrukt::Plugin Konstrukt::Attributes/;

=head1 METHODS

=cut

=head2 init

Method that will be called right before the first usage within a request.
Here you should do per request initialization work like definition of
L<default settings|Konstrukt::Settings/default>.

Should be overridden by the inheriting class.

=cut
#init() inherited from Konstrukt::Plugin

=head2 install

Should be overloaded by your plugin and its backends, if they need
installation before the first run.

The installation should be performed according to the current settings like
the selected backend and database settings as well as the template path.

Usually in the backend module this method will create database tables for your
plugin. The "main" plugin should load the backend plugin on init,
that is defined in the settings, and then the install method will be
called automatically on the backend module when it gets loaded.

The "main" plugin may create templates that are needed for the output. 

Will be called automatically after the plugin has been loaded and C<init()>ialized,
if the setting C<autoinstall> is true.

You may want to use L<Konstrukt::Lib/plugin_dbi_install_helper> for the
installation of your DBI backend plugins and
L<Konstrukt::Lib/plugin_file_install_helper> for the installation of default
templates for your plugin, which can be embedded at the end of your plugin module. 

Don't confuse this method with L</init>, which will be called once on B<every>
request.

B<Parameters:>

none

=cut
#inherited from Konstrukt::Plugin

#discouraged...
sub prepare_again { return 0; }

#very likely
sub execute_again { return 1; }

#too complicated
sub prepare {
	my ($self, $tag) = @_;
	$tag->{dynamic} = 1;
	return undef;
}

#dispatch the execution to the appropriate sub
sub execute {
	my ($self, $tag) = @_;
	
	#collect CGI parameters
	my @param_names = $Konstrukt::CGI->param();
	my %params = map { $_ => $Konstrukt::CGI->param($_) || undef } @param_names; #|| undef to prevent warning "Odd number of elements in hash assignment"
	
	#get plugin name and action
	my $plugin_name = $tag->{tag}->{type};
	my $action = $params{$plugin_name . '_action'};
	
	#collect text nodes and merge into a string
	my $content = '';
	my $node = $tag->{first_child};
	while (defined $node) {
		if ($node->{type} eq 'plaintext' or $node->{type} eq 'comment') {
			$content .= $node->{content};
		}
		$node = $node->{next};
	}
	
	#reset the dummy node to collect the output, activate print redirection, register for print events
	$self->reset_nodes();
	$Konstrukt::PrintRedirector->activate();
	$Konstrukt::Event->register("Konstrukt::PrintRedirector::print", $self, \&print_event);
	
	#try to execute the method for this action
	if (defined $action) {
		my $action_subname = "Konstrukt::Plugin::${plugin_name}::$action";
		if ($self->can($action)) {
			if ($Konstrukt::Attributes->has(\&{$action_subname} => 'Action')) {
				eval "\$self->$action(\$tag, \$content, \\%params)";
				#check for errors
				if (Konstrukt::Debug::ERROR and $@) {
					#Errors in eval
					chomp($@);
					$Konstrukt::Debug->error_message("Error while executing sub '$action_subname' for action '$action' of plugin '$plugin_name'!\n$@");
					print "[ERROR: Error while executing action '$action' for plugin '$plugin_name'! $@" . "]";
				}
			} else {
				#method not accessible from the outside!
				$Konstrukt::Debug->error_message("Action '$action' of plugin '$plugin_name' not accessible as an action! You must specify the 'Action' attribute for this method.") if Konstrukt::Debug::ERROR;
				print "[ERROR: Action '$action' of plugin '$plugin_name' not accessible as an action! You must specify the 'Action' attribute for this method.]";
			}
		} else {
			$Konstrukt::Debug->error_message("Plugin '$plugin_name' has no method for the called action '$action'!") if Konstrukt::Debug::ERROR;
			print "[ERROR: No code for action '$action' of plugin '$plugin_name'!]";
		}
	} else {
		if ($Konstrukt::Attributes->has(\&default => 'Action')) {
			#run default method
			$self->default($tag, $content, \%params);
		} else {
			#method not accessible from the outside!
			$Konstrukt::Debug->error_message("Action 'default' of plugin '$plugin_name' not accessible as an action! You must specify the 'Action' attribute for this method.") if Konstrukt::Debug::ERROR;
			print "[ERROR: Action 'default' of plugin '$plugin_name' not accessible as an action! You must specify the 'Action' attribute for this method.]";
		}
	}
	
	#deactivate print redirection, deregister for print events
	$Konstrukt::PrintRedirector->deactivate();
	$Konstrukt::Event->deregister_all_by_object("Konstrukt::PrintRedirector::print", $self);
	
	return $self->get_nodes();
}
#= /execute

#Accepts the "printredirector_print"-event and adds a plaintext node
#See docs of perl plugin for more info
sub print_event {
	my ($self, @data) = @_;
	
	if (defined $self->{collector_node}->{last_child} and $self->{collector_node}->{last_child}->{type} eq 'plaintext') {
		$self->{collector_node}->{last_child}->{content} .= join('', @data);
	} else {
		$self->add_node(join '', @data);
	}
	
	return 1;
}
#= /print_event

=head2 some_action : Action

You have to write a method for each "action" of your plugin. Your method
will then be called with the parameters listed below.

The action will be called with C<page.html?${yourpluginname}action=some_action>.

You may C<print> some output here:

	print 'something';

Or put out other plugin tags (e.g. L<templates|Konstrukt::Plugin::template>)
by adding L<nodes|Konstrukt::Parser::Node> to the result:

	#put out a template containing another template in a field:
	my $template = use_plugin 'template';
	$self->add_node($template->node('some.template', { some_field => $template->node('some_other.template') }));

B<Parameters>:

=over

=item * $tag - Reference to the tag node (and its children) that shall be handled.
Contains the plugin tag in the parse tree and all related information - especially
the tag attributes:

	my $source = $tag->{tag}->{attributes}->{src};

and the content inside the tag (via the parse tree nodes), which should be only
text and comment nodes:

	my $node = $tag->{first_child};
	while (defined $node) {
		#do stuff on $node->{content}...
		$node = $node->{next};
	}

=item * $content - The content below/inside the tag as a flat string.
(Might be easier to deal with in some cases)

=item * $params - Reference to a hash of the passed CGI parameters.

=back

=cut

=head2 default : Action

The default action handler of this plugin. This method will be called, when
no action has been specified. For some more info take a look at L</some_action>.

This sub should be overridden by the inheriting class.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=item * $content - The content below/inside the tag as a flat string.

=item * $params - Reference to a hash of the passed CGI parameters.

=back

=cut
sub default : Action {
	my ($self, $tag, $content, $params) = @_;
	
	$Konstrukt::Debug->error_message("Not overloaded!") if Konstrukt::Debug::ERROR;
	
	print 'Your plugin should do its work for the default action here!';
}
#= /default

=head1 METHODS NOT DOCUMENTED HERE

To keep it simple some methods that evey plugin has are not documented here,
as they are of minor relevance for "simple" plugin.

They are defined with good defaults for a simple plugin and you shouldn't need
to care about them. If you're interested in this methods nonetheless, read on!

=head2 prepare_again

Returns 0 by default.

See L<Konstrukt::Plugin/prepare_again> for more details.

=cut

=head2 execute_again

Returns 1 by default.

See L<Konstrukt::Plugin/execute_again> for more details.

=cut

=head2 prepare

Won't be used by default.

See L<Konstrukt::Plugin/prepare> for more details.

=cut

=head2 execute

Will handle the request internally and dispatch it to your action methods.

See L<Konstrukt::Plugin/execute> for more details.

=head2 print_event

Will  be used internally to catch the C<print>s of your plugin.

Works the same way as in L<Konstrukt::Plugin::perl/print_event>.

=cut

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt::Parser::Node>, L<Konstrukt>

=cut
