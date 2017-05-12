=head1 NAME

Konstrukt::Plugin::env - Access to the environment variables

=head1 SYNOPSIS

B<Usage:>
	
	<!-- set value -->
	<& env var="var_name" set="value" / &>

	<!-- print out value -->
	<& env var="var_name" / &>

B<Result:>

	<!-- set value -->

	<!-- print out value -->
	value

=head1 DESCRIPTION

This plugin will set or display specified environment variables.

=cut

package Konstrukt::Plugin::env;

use strict;
use warnings;

use base 'Konstrukt::SimplePlugin';
use Konstrukt::Debug; #import constants

=head1 ACTIONS

=head2 default

Put out the value of the passed ENV-variable or sets an ENV-variable.

Checks the passed tag for attributes like var="varname" and set="value".

With only var being passed, the according value of the environment will be put out.

With additionaly set being passed, the according value of the environment will be changed and nothing will be put out.

=cut
sub default : Action {
	my ($self, $tag, $content, $params) = @_;
	
	if (exists($tag->{tag}->{attributes}->{var}) and defined($tag->{tag}->{attributes}->{var})) {
		#var attribute is set
		if (exists($tag->{tag}->{attributes}->{set}) and defined($tag->{tag}->{attributes}->{set})) {
			#set attribute is also set. only set the value
			$Konstrukt::Handler->{ENV}->{$tag->{tag}->{attributes}->{var}} = $tag->{tag}->{attributes}->{set};
		} else {
			#only var attribute. no set
			#return the value if defined
			if (defined $Konstrukt::Handler->{ENV}->{$tag->{tag}->{attributes}->{var}}) {
				print $Konstrukt::Handler->{ENV}->{$tag->{tag}->{attributes}->{var}};
			} else {
				$Konstrukt::Debug->debug_message("The environment variable '$tag->{tag}->{attributes}->{var}' is not defined!") if Konstrukt::Debug::INFO;
			}
		}
	}
}
#= /default

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::SimplePlugin>, L<Konstrukt>

=cut
