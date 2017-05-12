package IPC::SRLock::Sysv;

use namespace::autoclean;

use English                qw( -no_match_vars );
use File::DataClass::Types qw( Object OctalNum PositiveInt );
use IPC::ShareLite         qw( :lock );
use IPC::SRLock::Utils     qw( Unspecified hash_from loop_until throw );
use Storable               qw( nfreeze thaw );
use Try::Tiny;
use Moo;

extends q(IPC::SRLock::Base);

# Attribute constructors
my $_build__share = sub {
   my $self = shift; my $share;

   try   { $share = IPC::ShareLite->new( '-key'    => $self->lockfile,
                                         '-create' => 1,
                                         '-mode'   => $self->mode,
                                         '-size'   => $self->size ) }
   catch {
      # uncoverable subroutine
      throw "${_}: ${OS_ERROR}"; # uncoverable statement
   };

   return $share;
};

# Public attributes
has 'lockfile' => is => 'ro',   isa => PositiveInt, default => 12_244_237;

has 'mode'     => is => 'ro',   isa => OctalNum, coerce => 1, default => '0666';

has 'size'     => is => 'ro',   isa => PositiveInt, default => 65_536;

# Private attributes
has '_share'   => is => 'lazy', isa => Object, builder => $_build__share;

# Construction
sub BUILD {
   my $self = shift; $self->_share; return;
}

# Private methods
my $_expire_lock = sub {
   my ($self, $data, $key, $lock) = @_;

   $self->log->error
      ( $self->_timeout_error
        ( $key, $lock->{spid}, $lock->{stime}, $lock->{timeout} ) );

   delete $data->{ $key };
   return 0;
};

my $_unlock_share = sub {
   my $self = shift; defined $self->_share->unlock and return 1;

   throw 'Failed to unset semaphore'; # uncoverable statement
};

my $_write_shared_mem = sub {
   my ($self, $data) = @_;

   try   { $self->_share->store( nfreeze $data ) }
   catch {
      throw "${_}: ${OS_ERROR}"; # uncoverable statement
   };

   return $self->$_unlock_share;
};

my $_read_shared_mem = sub {
   my ($self, $for_update, $async) = @_; my $data;

   my $mode = $for_update ? LOCK_EX : LOCK_SH; $async and $mode |= LOCK_NB;
   my $lock = $self->_share->lock( $mode );

   defined $lock or throw 'Failed to set semaphore';
   $lock or return; # Async operation would have blocked

   try   { $data = $self->_share->fetch; $data = $data ? thaw( $data ) : {} }
   catch {
      throw "${_}: ${OS_ERROR}"; # uncoverable statement
   };

   not $for_update and $self->$_unlock_share;
   return $data;
};

my $_reset = sub {
   my ($self, $args) = @_; my $key = $args->{k}; my $pid = $args->{p};

   my $shm_content = $self->$_read_shared_mem( 1 );

   my $lock; exists $shm_content->{ $key }
      and $lock = $shm_content->{ $key }
      and $lock->{spid} != $pid
      and $self->$_unlock_share
      and throw 'Lock [_1] set by another process', [ $key ];

   not delete $shm_content->{ $key } and $self->$_unlock_share
      and throw 'Lock [_1] not set', [ $key ];

   return $self->$_write_shared_mem( $shm_content );
};

my $_set = sub {
   my ($self, $args, $now) = @_; my $key = $args->{k}; my $pid = $args->{p};

   my $shm_content = $self->$_read_shared_mem( 1, $args->{async} ) or return 0;

   my $lock; exists $shm_content->{ $key }
      and $lock = $shm_content->{ $key }
      and $lock->{timeout}
      and $now > $lock->{stime} + $lock->{timeout}
      and $lock = $self->$_expire_lock( $shm_content, $key, $lock );

   $lock and $self->$_unlock_share and return 0;

   $shm_content->{ $key }
      = { spid => $pid, stime => $now, timeout => $args->{t} };
   $self->$_write_shared_mem( $shm_content );
   $self->log->debug( "Lock ${key} set by ${pid}" );
   return 1;
};

# Public methods
sub list {
   my $self = shift; my $data = $self->$_read_shared_mem; my $list = [];

   while (my ($key, $info) = each %{ $data }) {
      push @{ $list }, { key     => $key,
                         pid     => $info->{spid   },
                         stime   => $info->{stime  },
                         timeout => $info->{timeout} };
   }

   return $list;
}

sub reset {
   my $self = shift; return $self->$_reset( $self->_get_args( @_ ) );
}

sub set {
   my ($self, @args) = @_; return loop_until( $_set )->( $self, @args );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

IPC::SRLock::Sysv - Set / reset locks using System V IPC

=head1 Synopsis

   use IPC::SRLock;

   my $config   = { type => q(sysv) };

   my $lock_obj = IPC::SRLock->new( $config );

=head1 Description

Uses System V semaphores to lock access to a shared memory file

=head1 Configuration and Environment

This class defines accessors for these attributes:

=over 3

=item C<lockfile>

The key the the semaphore. Defaults to 12_244_237

=item C<mode>

Mode to create the shared memory file. Defaults to 0666

=item C<size>

Maximum size of a shared memory segment. Defaults to 65_536

=back

=head1 Subroutines/Methods

=head2 BUILD

Create the shared memory segment at construction time

=head2 list

List the contents of the lock table

=head2 reset

Delete a lock from the lock table

=head2 set

Set a lock in the lock table

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass>

=item L<IPC::ShareLite>

=item L<IPC::SRLock::Base>

=item L<Moo>

=item L<Storable>

=item L<Time::HiRes>

=item L<Try::Tiny>

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
