package IPC::SRLock;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.31.%d', q$Rev: 1 $ =~ /\d+/gmx );

use File::DataClass::Types qw( HashRef LoadableClass NonEmptySimpleStr Object );
use IPC::SRLock::Utils     qw( merge_attributes );
use Moo;

my $_build__implementation = sub {
   return $_[ 0 ]->_implementation_class->new( $_[ 0 ]->_implementation_attr );
};

my $_build__implementation_class = sub {
   my $self = shift; my $type = $self->type; my $class;

   if ('+' eq substr $type, 0, 1) { $class = substr $type, 1 }
   else { $class = __PACKAGE__.'::'.(ucfirst $type) }

   return $class;
};

# Public attributes
has 'type' => is => 'ro', isa => NonEmptySimpleStr, default => 'fcntl';

# Private attributes
has '_implementation'       => is => 'lazy', isa => Object,
   handles                  => [ qw( get_table list reset set ) ],
   builder                  => $_build__implementation;

has '_implementation_attr'  => is => 'ro',   isa => HashRef, required => 1;

has '_implementation_class' => is => 'lazy', isa => LoadableClass,
   builder                  => $_build__implementation_class;

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args );

   my $builder = $attr->{builder};
   my $conf    = $builder && $builder->can( 'config' ) ? $builder->config : 0;

   $conf and $conf->can( 'lock_attributes' )
         and merge_attributes $attr, $conf->lock_attributes,
                           [ keys %{ $conf->lock_attributes } ];

   $attr->{name} //= lc join '_', split m{ :: }mx, __PACKAGE__, -1;

   my $type = delete $attr->{type}; $attr = { _implementation_attr => $attr };

   $type and $type !~ m{ \A ([a-zA-Z0-9\:\+]+) \z }mx
         and die "Type ${type} tainted";
   $type and $attr->{type} = $1;

   return $attr;
};

sub BUILD {
   my $self = shift; $self->_implementation; return;
}

1;

__END__

=pod

=encoding utf-8

=begin html

<a href="https://travis-ci.org/pjfl/p5-ipc-srlock"><img src="https://travis-ci.org/pjfl/p5-ipc-srlock.svg?branch=master" alt="Travis CI Badge"></a>
<a href="https://roxsoft.co.uk/coverage/report/ipc-srlock/latest"><img src="https://roxsoft.co.uk/coverage/badge/ipc-srlock/latest" alt="Coverage Badge"></a>
<a href="http://badge.fury.io/pl/IPC-SRLock"><img src="https://badge.fury.io/pl/IPC-SRLock.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/IPC-SRLock"><img src="http://cpants.cpanauthors.org/dist/IPC-SRLock.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

IPC::SRLock - Set / reset locking semantics to single thread processes

=head1 Version

This documents version v0.31.$Rev: 1 $ of L<IPC::SRLock>

=head1 Synopsis

   use IPC::SRLock;

   my $config   = { tempdir => 'path_to_tmp_directory', type => 'fcntl' };

   my $lock_obj = IPC::SRLock->new( $config );

   $lock_obj->set( k => 'some_resource_identfier' );

   # This critical region of code is guaranteed to be single threaded

   $lock_obj->reset( k => 'some_resource_identfier' );

=head1 Description

Provides set/reset locking methods which will force a critical region
of code to run single threaded

Implements a factory pattern, three implementations are provided. The
LCD option L<IPC::SRLock::Fcntl> which works on non Unixen,
L<IPC::SRLock::Sysv> which uses System V IPC, and
L<IPC::SRLock::Memcached> which uses C<libmemcache> to implement a
distributed lock manager

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<type>

Determines which factory subclass is loaded. Defaults to C<fcntl>, can
be; C<fcntl>, C<memcached>, or C<sysv>

=back

=head1 Subroutines/Methods

=head2 BUILDARGS

Extracts the C<type> attribute from those passed to the factory subclass

=head2 BUILD

Called after an instance is created this subroutine triggers the lazy
evaluation of the concrete subclass

=head2 get_table

   my $data = $lock_obj->get_table;

Returns a hash ref that contains the current lock table contents. The
keys/values in the hash are suitable for passing to
L<HTML::FormWidgets>

=head2 list

   my $array_ref = $lock_obj->list;

Returns an array of hash refs that represent the current lock table

=head2 reset

   $lock_obj->reset( k => 'some_resource_key' );

Resets the lock referenced by the C<k> attribute.

=head2 set

   $lock_obj->set( k => 'some_resource_key' );

Sets the specified lock. Attributes are:

=over 3

=item C<k>

Unique key to identify the lock. Mandatory no default

=item C<p>

Explicitly set the process id associated with the lock. Defaults to
the current process id

=item C<t>

Set the time to live for this lock. Defaults to five minutes. Setting
it to zero makes the lock last indefinitely

=back

=head1 Diagnostics

Setting C<debug> to true will cause the C<set> methods to log
the lock record at the debug level

=head1 Dependencies

=over 3

=item L<File::DataClass>

=item L<Moo>

=item L<Type::Tiny>

=back

=head1 Incompatibilities

The C<sysv> subclass type will not work on C<MSWin32> and C<cygwin> platforms

=head1 Bugs and Limitations

Testing of the C<memcached> subclass type is skipped on all platforms as it
requires C<memcached> to be listening on the localhost's default
memcached port C<localhost:11211>

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
