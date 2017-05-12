package IPC::SRLock::Utils;

use strict;
use warnings;
use parent 'Exporter::Tiny';

use IPC::SRLock::Constants qw( EXCEPTION_CLASS );
use Scalar::Util           qw( blessed );

our @EXPORT_OK = qw( Unspecified hash_from loop_until merge_attributes throw );

sub Unspecified () {
   return sub { 'Unspecified' };
}

sub hash_from  (;@) {
   my (@args) = @_; $args[ 0 ] or return {};

   return ref $args[ 0 ] ? $args[ 0 ] : { @args };
}

sub loop_until ($) {
   my $f = shift;

   return sub {
      my $self = shift; my $args = $self->_get_args( @_ ); my $start = time;

      while (1) {
         my $now = time;
         my $r   = $f->( $self, $args, $now ); $r and return $r;

         # uncoverable branch false
         $args->{async} and return 0;
         # uncoverable statement
         $self->_sleep_or_timeout( $start, $now, $self->lockfile );
      }
   };
}

sub merge_attributes ($$;$) {
   my ($dest, $src, $keys) = @_; my $class = blessed $src;

   for (grep { not exists $dest->{ $_ } or not defined $dest->{ $_ } }
            @{ $keys // [] }) {
      my $v = $class ? ($src->can( $_ ) ? $src->$_() : undef) : $src->{ $_ };

      defined $v and $dest->{ $_ } = $v;
   }

   return $dest;
}

sub throw (;@) {
   EXCEPTION_CLASS->throw( @_ );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

IPC::SRLock::Utils - Common functions used by this distribution

=head1 Synopsis

   use IPC::SRLock::Utils qw( Unspecified hash_from get_args );

=head1 Description

Common functions used by this distribution

=head1 Subroutines/Methods

=head2 Unspecified

Returns a subroutine reference which when called returns the string
C<Unspecified>. This is an exception class used as an argument to the
L<throw|IPC::SRLock::Base/throw> method

=head2 hash_from

Returns a hash reference. Accepts a hash reference or a list of keys and
values

=head2 loop_until

Loop until the closed over subroutine returns true or a timeout occurs

=head2 merge_attributes

   $dest = merge_attributes $dest, $src, $attr_list_ref;

Merges attribute hashes. The C<$dest> hash is updated and
returned. The C<$dest> hash values take precedence over the C<$src>
hash values. The C<$src> hash may be an object in which case its
accessor methods are called

=head2 throw

Expose the C<throw> method in L<File::DataClass::Exception>

=head1 Configuration and Environment

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Exporter::Tiny>

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
