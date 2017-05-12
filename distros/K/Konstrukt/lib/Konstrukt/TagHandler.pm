=head1 NAME

Konstrukt::TagHandler - Base class for the tag handlers.

=head1 SYNOPSIS
	
	use Konstrukt::TagHandler;
	use vars qw(@ISA);
	@ISA = qw(Konstrukt::TagHandler);

=head1 DESCRIPTION

Baseclass for <#!$ ... $!#>-tag handlers, where "#!$" is the identifier of the tag type.

=cut

package Konstrukt::TagHandler;

use strict;
use warnings;

use Konstrukt::Debug;

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

Method that will be called right after construction of this object.
Should be overridden by the inheriting class.

=cut
sub init {
	return 1;
}
#= /init

=head2 prepare

Method that will call the prepare procedure of the specified tag.
Should be overridden by the inheriting class.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	$Konstrukt::Debug->error_message("Not overloaded!") if Konstrukt::Debug::ERROR;
	
	return [];
}
#= /prepare

=head2 execute

Method that will call the execute procedure of the specified tag.
Should be overridden by the inheriting class.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;
	
	$Konstrukt::Debug->error_message("Not overloaded!") if Konstrukt::Debug::ERROR;
	
	return [];
}
#= /execute

=head2 prepare_again

Should return true, when this tag may generate plaintext that will parse to
dynamic content (e.g. return plaintext nodes that contain Konstrukt tags (<& .. &>)).

Should be overwritten by the inheriting class.

=cut
sub prepare_again {
	return 0;
}
#= /prepare_again

=head2 execute_again

Should return true, when this tag may generate (dynamic) tag nodes that shall
be executed (e.g. return an template or perl node).

=cut
sub execute_again {
	return 0;
}
#= /execute_again

=head2 executionstage

Returns the execution stage of the tag. Defaults to 1.

Usually all tags are L</execute>d in the order of appearence in the processed
document.

But sometimes you might want a tag to be executed last/later, although it's 
located at the top of the document.
The C<executionstage>s allow to specifiy an execution order that's different
from the appearance order.

	<& perl executionstage="2" &>print `date +%H:%M:%S`<& / &>
	<& perl &>print `date +%H:%M:%S`; sleep 2<& / &>

Will actually be rendered to something like:

	10:50:54
	10:50:52

=cut
sub executionstage {
	return 1;
}
#= /executionstage

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt>

=cut
