package File::DataClass::Result;

use namespace::autoclean;

use Moo;
use File::DataClass::Types qw( Object Str );

has 'id' => is => 'rw', isa => Str, required => 1;

has '_result_source' => is => 'ro', isa => Object,
   handles  => { _path => 'path', _storage => 'storage' },
   init_arg => 'result_source', reader => 'result_source',
   required => 1, weak_ref => 1;

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args );

   my $name = delete $attr->{name}; $attr->{id} //= $name;

   return $attr;
};

sub delete {
   return $_[ 0 ]->_storage->delete( $_[ 0 ]->_path, $_[ 0 ] );
}

sub insert {
   return $_[ 0 ]->_storage->insert( $_[ 0 ]->_path, $_[ 0 ] );
}

sub name { # Deprecated
   return defined $_[ 1 ] ? $_[ 0 ]->id( $_[ 1 ] ) : $_[ 0 ]->id;
}

sub update {
   return $_[ 0 ]->_storage->update( $_[ 0 ]->_path, $_[ 0 ] );
}

1;

__END__

=pod

=head1 Name

File::DataClass::Result - Result object definition

=head1 Synopsis

=head1 Description

This is analogous to the result object in L<DBIx::Class>

=head1 Configuration and Environment

Defines these attributes

=over 3

=item B<id>

An additional attribute added to the result to store the underlying hash
key

=item B<result_source>

An object reference to the L<File::DataClass::ResultSource> instance for
this result object

=back

=head1 Subroutines/Methods

=head2 BUILDARGS

Replaces the deprecated C<name> attribute with C<id>

=head2 BUILD

Creates accessors and mutators for the attributes defined by the
schema class

=head2 delete

   $result->delete;

Calls the delete method in the storage class

=head2 insert

   $result->insert;

Calls the insert method in the storage class

=head2 name

   $result->name;

Defined as an alias for the C<id> attribute, use of this attribute is
deprecated

=head2 update

   $result->update;

Calls the update method in the storage class

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=item L<MooX::ClassStash>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
