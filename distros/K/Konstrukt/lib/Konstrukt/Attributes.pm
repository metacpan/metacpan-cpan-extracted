=head1 NAME

Konstrukt::Attributes - Sub attribute handling

=head1 SYNOPSIS

	#define a method with an attribute
	sub some_sub :some_attr {
		#...
	}
	
	#check if a sub has a specified attribute
	$Konstrukt::Attributes->has(\&some_sub => 'some_attr');

=head1 DESCRIPTION

This module collects the attribute definitions for the methods of the (loaded)
plugins and allows to check if a given method has a specified attribute.

With this information you may for example decide to execute a method or not.

Attributes are primarily used in L<Konstrukt::SimplePlugin>.

To enable the attribute collection your module must import the
C<MODIFY_CODE_ATTRIBUTES> of this package. This can be done this way:

	use base 'Konstrukt::Attributes';

=cut

package Konstrukt::Attributes;

use strict;
use warnings;

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

Initialization.

=cut
sub init {
	my ($self) = @_;
	$Konstrukt::Attributes::Container = {}; #reset attribute container
}
# /init

=head2 has

Returns true if the given sub has a specified attribute.

Parameters:

=over

=item * $coderef - Coderef to the sub/method

=item * $attribute - The name of the attribute

=back

=cut
sub has {
	my ($self, $coderef, $attribute) = @_;
	return scalar map { $_ eq $attribute ? 1 : () } @{$Konstrukt::Attributes::Container->{$coderef}};
}
#= /has

=head1 INTERNALS

=head2 MODIFY_CODE_ATTRIBUTES

This sub does the real work. It captures the definition of attributes during
compile time and saves them for later use.

=cut
sub MODIFY_CODE_ATTRIBUTES {
   my ($package, $coderef, @attributes) = @_;
   $Konstrukt::Attributes::Container->{$coderef} = \@attributes;
	return ();
}
#= /MODIFY_CODE_ATTRIBUTES

#create global object
sub BEGIN { $Konstrukt::Attributes = __PACKAGE__->new() unless defined $Konstrukt::Attributes; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt>

=cut
