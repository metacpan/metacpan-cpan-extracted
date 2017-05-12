package IPC::SRLock::Base;

use namespace::autoclean;

use Date::Format           qw( time2str );
use English                qw( -no_match_vars );
use File::DataClass::Types qw( Bool LoadableClass NonEmptySimpleStr
                               Num Object PositiveInt );
use IPC::SRLock::Utils     qw( Unspecified hash_from merge_attributes throw );
use Time::Elapsed          qw( elapsed );
use Time::HiRes            qw( usleep );
use Moo;

# Public attributes
has 'debug'       => is => 'ro',   isa => Bool, default => 0;

has 'log'         => is => 'lazy', isa => Object,
   builder        => sub { $_[ 0 ]->_null_class->new };

has 'name'        => is => 'ro',   isa => NonEmptySimpleStr, required => 1;

has 'nap_time'    => is => 'ro',   isa => Num, default => 0.1;

has 'patience'    => is => 'ro',   isa => PositiveInt, default => 0;

has 'time_out'    => is => 'ro',   isa => PositiveInt, default => 300;

# Private attributes
has '_null_class' => is => 'lazy', isa => LoadableClass,
   default        => 'Class::Null', init_arg => undef;

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args );

   my $builder = $attr->{builder} or return $attr;

   merge_attributes $attr, $builder, [ 'debug', 'log' ];

   return $attr;
};

# Private methods
sub _get_args {
   my $self = shift; my $args = hash_from @_;

   $args->{k}  or throw Unspecified, [ 'key' ]; $args->{k} .= q();
   $args->{p} //= $PID; # uncoverable condition false
   $args->{t} //= $self->time_out; # uncoverable condition false

   return $args;
}

sub _sleep_or_timeout {
   my ($self, $start, $now, $key) = @_;

   $self->patience and $now > $start + $self->patience
      and throw 'Lock [_1] timed out', [ $key ];
   usleep( 1_000_000 * $self->nap_time );
   return 1;
}

sub _timeout_error {
   my ($self, $key, $pid, $when, $after) = @_;

   return "Timed out ${key} set by ${pid} on "
        . time2str( '%Y-%m-%d at %H:%M', $when )." after ${after} seconds\n";
}

# Public methods
sub get_table {
   my $self  = shift;
   my $count = 0;
   my $data  = { align  => { id    => 'left',
                             pid   => 'right',
                             stime => 'right',
                             tleft => 'right'},
                 count  => $count,
                 fields => [ qw( id pid stime tleft ) ],
                 hclass => { id    => 'most' },
                 labels => { id    => 'Key',
                             pid   => 'PID',
                             stime => 'Lock Time',
                             tleft => 'Time Left' },
                 values => [] };

   for my $lock (@{ $self->list }) {
      my $fields = {};

      $fields->{id   } = $lock->{key};
      $fields->{pid  } = $lock->{pid};
      $fields->{stime} = time2str( '%Y-%m-%d %H:%M:%S', $lock->{stime} );

      my $tleft = $lock->{stime} + $lock->{timeout} - time;

      # uncoverable branch false
      $fields->{tleft} = $tleft > 0 ? elapsed( $tleft ) : 'Expired';
      push @{ $data->{values} }, $fields; $count++;
   }

   $data->{count} = $count;
   return $data;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

IPC::SRLock::Base - Common lock object attributes and methods

=head1 Synopsis

   package IPC::SRLock::<some_new_mechanism>;

   use Moo;

   extents 'IPC::SRLock::Base';

=head1 Description

This is the base class for the factory subclasses of L<IPC::SRLock>. The
factory subclasses all inherit from this class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<debug>

Turns on debug output. Defaults to 0

=item C<exception_class>

Class used to throw exceptions

=item C<log>

If set to a log object, it's C<debug> method is called if debugging is
turned on. Defaults to L<Class::Null>

=item C<name>

Used as the lock file names. Defaults to C<ipc_srlock>

=item C<nap_time>

How long to wait between polls of the lock table. Defaults to 0.5 seconds

=item C<patience>

Time in seconds to wait for a lock before giving up. If set to 0 waits
forever. Defaults to 0

=item C<pid>

The process id doing the locking. Defaults to this processes id

=item C<time_out>

Time in seconds before a lock is deemed to have expired. Defaults to 300

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

Extract L</debug> and L</log> attribute values from the C<builder> object
if one was supplied

=head2 C<get_table>

   my $data = $lock_obj->get_table;

Returns a hash ref that contains the current lock table contents. The
keys/values in the hash are suitable for passing to
L<HTML::FormWidgets>

=head2 C<list>

   my $array_ref = $lock_obj->list;

Returns an array of hash refs that represent the current lock table

=head2 C<reset>

   $lock_obj->reset( k => 'some_resource_key', ... );

Resets the lock referenced by the C<k> attribute.

=head2 C<set>

   $lock_obj->set( k => 'some_resource_key', ... );

Sets the specified lock. Attributes are;

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

=head2 _get_args

Default arguments for the C<set> method

=head2 _sleep_or_timeout

Sleep for a bit or throw a timeout exception

=head2 _timeout_error

Return the text of the the timeout message

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Null>

=item L<Class::Usul>

=item L<Date::Format>

=item L<File::DataClass>

=item L<Moo>

=item L<Time::Elapsed>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
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
