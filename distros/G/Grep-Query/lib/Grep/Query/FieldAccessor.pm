# for now, a fairly simple container for field names => code pieces to retrieve the actual data
#
package Grep::Query::FieldAccessor;

use strict;
use warnings;

use Carp;
our @CARP_NOT = qw(Regexp::Query);

## CTOR
##
sub new
{
	my $class = shift;
	my $optionalAccessors = shift;

	my $self = { _fields => {} };
	bless($self, $class);
	
	if (defined($optionalAccessors))
	{
		croak("accessors must be a hash") unless ref($optionalAccessors) eq 'HASH';
		$self->add($_, $optionalAccessors->{$_}) foreach (keys(%$optionalAccessors));
	}
	
	return $self;
}

sub add
{
	my $self = shift;
	my $field = shift;
	my $accessor = shift;
	
	croak("accessor field name must be a simple scalar string") if ref($field);
	croak("accessor must be code") unless ref($accessor) eq 'CODE';
	croak("field $field already set") if exists($self->{_fields}->{$field});	

	$self->{_fields}->{$field} = $accessor;
}

sub access
{
	my $self = shift;
	my $field = shift;
	my $obj = shift;
	
	return $self->assertField($field)->($obj);
}

sub assertField
{
	my $self = shift;
	my $field = shift;

	my $accessor = $self->{_fields}->{$field};
	croak("invalid field name '$field'") unless $accessor;
	
	return $accessor;
}

1;

=head1 NAME

Grep::Query::FieldAccessor - Helper object to hold methods to access fields in the supplied hashes/objects

=head1 SYNOPSIS

  use Grep::Query::FieldAccessor;

  # fill up an object with accessors
  #
  my $fieldAccessor1 = Grep::Query::FieldAccessor->new();
  $fieldAccessor1->add('name', sub { $_[0]->getName() });
  $fieldAccessor1->add('age', sub { $_[0]->calculateAge() });
  ...
  
  # equal, but provide it all in one go
  #
  my $fieldAccessor2 = Grep::Query::FieldAccessor->new
      (
          {
              name => sub { $_[0]->getName() },
              age => sub { $_[0]->calculateAge() },
              ...
          }
      );

=head1 DESCRIPTION

When using a L<Grep::Query> holding a query denoting fields, an object of this
type must be passed along.

It must contain methods, indexed on field names, that given an item in the
queried list, can extract the value to compare with.

B<Beware:> Ensure the methods supplied don't cause side-effects when they are
called (such as causing the object or other things to change). 

=head1 METHODS

=head2 new( [ $hash ] )

Creates a new field accessor object.

If the optional C<$hash> is provided, fields will be populated from it,
otherwise the L</add> method must be used.

=head2 add( $fieldname, $sub )

Adds an accessor for the given field.

Croaks if the params don't seem to be what they should be or if a field is
added more than once.

=head2 access( $fieldname, $obj )

(normally used by the internal query execution)

Looks up the code sub for the given field and executes it with obj as a
parameter and returns the result. 

=head2 assertField

(normally used by the internal query execution)

Retrieves the code sub for the given field.

Croaks if no such field is defined.

=head1 AUTHOR

Kenneth Olwing, C<< <knth at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-grep-query at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Grep-Query>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Grep::Query


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Grep-Query>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Grep-Query>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Grep-Query>

=item * Search CPAN

L<http://metacpan.org/dist/Grep-Query/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Kenneth Olwing.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
