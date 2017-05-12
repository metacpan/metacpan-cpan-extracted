
package HTML::Transmorgify::ObjectGlue;

use strict;

sub text { die };
sub lookup { die };
sub expand { die }
sub set { die };

1;

__END__

=head1 NMAE

 HTML::Transmorgify::ObjectGlue - virtual base clase for HTML::Transmorgify::Metatags objects

=head1 SYNOPSIS

 use base qw(HTML::Transmorgify::ObjectGlue);

 sub text
 {
 	my ($self) = @_;
	return "a text representation of the whole object"
 }

 sub lookup
 {
 	my ($self, $key) = @_;
	return $a_subkey_of_the_object;
 }

 sub expand
 {
 	my ($self) = @_;
	return @a_list_of_items_in_the_object
 }

 sub set
 {
 	my ($self, $key, $value) = @_;
	maybe: $self->{$key} = $value 
 }

=head1 DESCRIPTION

This is a virtual base class for L<HTML::Transmorgify> variables that are 
accessed by L<HTML::Transmorgify::Metatags> directives.

Variables can have multiple components to their names, separated with
dot (.) and the components will be looked up one-by-one.

There are four methods that need to be implemented:

=over 12

=item text()

Convert the entire object to a text string.

=item lookup($key)

Look up a value within the object.  The return value can be a scalar,
a hash ref, an array ref, or another HTML::Transmorgify::ObjectGlue-based
object.

=item expand

Return a list of the sub-objects in the object.  This is used by 
L<HTML::Transmorgify::Metatags> for iterating over the sub-objects
with E<lt>foreachE<gt>.

=item set

XXX




