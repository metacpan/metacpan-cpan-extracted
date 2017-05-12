package IPC::SRLock::Fake;

use namespace::autoclean;

use Moo;

extends q(IPC::SRLock::Base);

sub list {
   return [];
}

sub reset {
   return 1;
}

sub set {
   my $self = shift; my $args = $self->_get_args( @_ );

   my $key = $args->{k}; my $pid = $args->{p};

   $self->log->debug( "Lock ${key} set by ${pid}" );
   return 1;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

IPC::SRLock::Fake - Does nothing but dummy up the public methods in the API

=head1 Synopsis

   use IPC::SRLock;

   my $lock = IPC::SRLock->new( { type => 'fake' } );

   $lock->set( k => 'key' );
   # Your code goes here...
   $lock->reset( k => 'key' );

=head1 Description

Does nothing but dummy up the public methods in the API

=head1 Configuration and Environment

Defines no additional attributes;

=head1 Subroutines/Methods

=head2 list

Returns an empty array reference

=head2 reset

Returns true

=head2 set

Returns true

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-SRLock.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

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
# vim: expandtab shiftwidth=3:
