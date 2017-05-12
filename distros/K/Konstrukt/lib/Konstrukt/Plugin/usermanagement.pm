#FEATURE: user administration: manually add, delete, modify users
#FEATURE: access control lists: user/group/object

=head1 NAME

Konstrukt::Plugin::usermanagement - User management. Extensible with plugins.

=head1 SYNOPSIS
	
=head2 Tag interface

	<!-- show basic user management -->
	<& usermanagement::basic / &>
	
	<!-- show personal data -->
	<& usermanagement::personal / &>
	
	<!-- show user levels -->
	<& usermanagement::personal / &>
	
	<!-- ... see the docs of each usermanagement plugin -->

=head2 Perl interface

	#within your plugin's init sub you should use the wanted modules
	use Konstrukt::Plugin;
	sub init {
		#...
		#example for the basic plugin. the usage of the others is similar.
		$self->{user_basic} = use_plugin 'usermanagement::basic' or return undef;
	}
	#then you may use the plugin
	sub my_method {
		my $uid = $self->{user_basic}->id();
	}

=head1 DESCRIPTION

Parent class for the Konstrukt user management plugins.

Actually this one doesn't do anything. All work is done in each
usermanagement::* plugin (see L</SEE ALSO>).

=head1 CONFIGURATION

See the documentation for each usermanagement plugin (see L</SEE ALSO>).

=cut

package Konstrukt::Plugin::usermanagement;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

use Konstrukt::Debug;

=head1 METHODS

=head2 execute_again

No, this plugin won't return dynamic nodes.

=cut
sub execute_again {
	return 0;
}

=head2 prepare

Prepare method

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare { 
	my ($self, $tag) = @_;

	#Don't do anything beside setting the dynamic-flag
	$tag->{dynamic} = 1;
	
	return undef;
}
#= /prepare

=head2 execute

Execute method

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;
	#the work is done each plugin
	return undef;
}
#= /execute

=head2 init

Initializes this object. Will load the plugins.
init will be called by the constructor.

=cut
sub init {
	return 1;
}
#= /init

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::usermanagement::basic>, L<Konstrukt::Plugin::usermanagement::level>,
L<Konstrukt::Plugin::usermanagement::personal>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut
