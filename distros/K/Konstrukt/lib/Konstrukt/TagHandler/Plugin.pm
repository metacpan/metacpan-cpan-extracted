=head1 NAME

Konstrukt::TagHandler::Plugin - Plugin handler of the Konstrukt framework

=head1 SYNOPSIS
	
	#use inside the parser
	use Konstrukt::TagHandler::Plugin;
	my $handler = Konstrukt::TagHandler::Plugin->new();
	my $result;
	$result = $handler->prepare($tag_node);
	$result = $handler->execute($tag_node);

=head1 DESCRIPTION

Handler for <& ... &>-tags (plugins).

=cut

package Konstrukt::TagHandler::Plugin;

use strict;
use warnings;

use Konstrukt::Debug;

use base 'Konstrukt::TagHandler';

=head1 METHODS

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	#reset loaded plugins. they must be init'ed again at every request
	$self->{plugins} = {};
	return 1;
}
#= /init

=head2 prepare

Implementation of L<Konstrukt::TagHandler/prepare>.

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	my $plugin = $tag->{tag}->{type};
	$self->load_plugin($plugin) unless exists $self->{plugins}->{$plugin};
	return exists $self->{plugins}->{$plugin} ? $self->{plugins}->{$plugin}->prepare($tag) : undef;
}
#= /prepare

=head2 execute

Implementation of L<Konstrukt::TagHandler/execute>.

=cut
sub execute {
	my ($self, $tag) = @_;
	
	my $plugin = $tag->{tag}->{type};
	$self->load_plugin($plugin) unless exists $self->{plugins}->{$plugin};
	return exists $self->{plugins}->{$plugin} ? $self->{plugins}->{$plugin}->execute($tag) : undef;
}
#= /execute

=head2 prepare_again

Implementation of L<Konstrukt::TagHandler/prepare_again>.

=cut
sub prepare_again {
	my ($self, $tag) = @_;
	
	my $plugin = $tag->{tag}->{type};
	$self->load_plugin($plugin) unless exists $self->{plugins}->{$plugin};
	return exists $self->{plugins}->{$plugin} ? $self->{plugins}->{$plugin}->prepare_again() : undef;
}
#= /prepare_again

=head2 execute_again

Implementation of L<Konstrukt::TagHandler/execute_again>.

=cut
sub execute_again {
	my ($self, $tag) = @_;
	
	my $plugin = $tag->{tag}->{type};
	$self->load_plugin($plugin) unless exists $self->{plugins}->{$plugin};
	return exists $self->{plugins}->{$plugin} ? $self->{plugins}->{$plugin}->execute_again() : undef;
}
#= /execute_again

=head2 executionstage

Implementation of L<Konstrukt::TagHandler/executionstage>.

=cut
sub executionstage {
	my ($self, $tag) = @_;
	
	my $plugin = $tag->{tag}->{type} || '';
	$self->load_plugin($plugin) unless exists $self->{plugins}->{$plugin};
	return exists $self->{plugins}->{$plugin} ? $self->{plugins}->{$plugin}->executionstage() : undef;
}
#= /executionstage

=head2 load_plugin

Loads and initializes a specified plugin.

Returns an object of this plugin if it could be loaded, undef otherwise.

B<Parameters>:

=over

=item * $plugin - Name of the plugin to load.

=back

=cut
sub load_plugin {
	#may also be called as function (use_plugin) and not as method
	my ($self, $plugin) = scalar @_ == 2 ? @_ : ($Konstrukt::TagHandler::Plugin, @_);
	
	#load and initialize plugin if not already done
	if (not exists $self->{plugins}->{$plugin}) {
		#load module
		eval "use Konstrukt::Plugin::$plugin";
		if ($@) { #Errors in eval
			chomp($@);
			$Konstrukt::Debug->error_message("Could not load module for plugin '$plugin'! $@") if Konstrukt::Debug::ERROR;
		} else {
			$Konstrukt::Debug->debug_message("Loading plugin '$plugin'") if Konstrukt::Debug::DEBUG;
			#create global object
			eval "\$Konstrukt::Plugin::$plugin = Konstrukt::Plugin::$plugin->new() unless defined \$Konstrukt::Plugin::$plugin";
			if ($@) { #Errors in eval
				chomp($@);
				$Konstrukt::Debug->error_message("Could not create plugin object for plugin '$plugin'! $@") if Konstrukt::Debug::ERROR;
			} else {
				#initialize
				$self->{plugins}->{$plugin} = 'dummy'; #set it to a dummy value to prevent recursive plugin initialization on dependency circles
				no strict 'refs';
				if (${"Konstrukt::Plugin::$plugin"}->init()) {
					#save plugin:
					$self->{plugins}->{$plugin} = ${"Konstrukt::Plugin::$plugin"};
					#auto-initialization:
					if ($Konstrukt::Settings->get('autoinstall')) {
						$Konstrukt::Debug->debug_message("Doing auto-installation for '$plugin'. Set 'autoinstall' to 0 in your konstrukt.settings to disable it.") if Konstrukt::Debug::INFO;
						$self->{plugins}->{$plugin}->install();
					}
				} else {
					$Konstrukt::Debug->error_message("Could not initialize plugin '$plugin'! $@") if Konstrukt::Debug::ERROR;
					delete $self->{plugins}->{$plugin};
				}
				use strict 'refs';
			}
		}
	}
	
	return $self->{plugins}->{$plugin};
}
#= /load_plugin

#create global object
sub BEGIN { $Konstrukt::TagHandler::Plugin = __PACKAGE__->new() unless defined $Konstrukt::TagHandler::Plugin; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut
