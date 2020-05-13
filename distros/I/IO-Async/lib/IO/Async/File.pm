#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2015 -- leonerd@leonerd.org.uk

package IO::Async::File;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( IO::Async::Timer::Periodic );

use Carp;
use File::stat;

# No point watching blksize or blocks
my @STATS = qw( dev ino mode nlink uid gid rdev size atime mtime ctime );

=head1 NAME

C<IO::Async::File> - watch a file for changes

=head1 SYNOPSIS

 use IO::Async::File;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $file = IO::Async::File->new(
    filename => "config.ini",
    on_mtime_changed => sub {
       my ( $self ) = @_;
       print STDERR "Config file has changed\n";
       reload_config( $self->handle );
    }
 );

 $loop->add( $file );

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Notifier> watches an open filehandle or named
filesystem entity for changes in its C<stat()> fields. It invokes various
events when the values of these fields change. It is most often used to watch
a file for size changes; for this task see also L<IO::Async::FileStream>.

While called "File", it is not required that the watched filehandle be a
regular file. It is possible to watch anything that C<stat(2)> may be called
on, such as directories or other filesystem entities.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters.

=head2 on_dev_changed $new_dev, $old_dev

=head2 on_ino_changed $new_ino, $old_ino

=head2 ...

=head2 on_ctime_changed $new_ctime, $old_ctime

Invoked when each of the individual C<stat()> fields have changed. All the
C<stat()> fields are supported apart from C<blocks> and C<blksize>. Each is
passed the new and old values of the field.

=head2 on_devino_changed $new_stat, $old_stat

Invoked when either of the C<dev> or C<ino> fields have changed. It is passed
two L<File::stat> instances containing the complete old and new C<stat()>
fields. This can be used to observe when a named file is renamed; it will not
be observed to happen on opened filehandles.

=head2 on_stat_changed $new_stat, $old_stat

Invoked when any of the C<stat()> fields have changed. It is passed two
L<File::stat> instances containing the old and new C<stat()> fields.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>.

=head2 handle => IO

The opened filehandle to watch for C<stat()> changes if C<filename> is not
supplied.

=head2 filename => STRING

Optional. If supplied, watches the named file rather than the filehandle given
in C<handle>. The file will be opened for reading and then watched for
renames. If the file is renamed, the new filename is opened and tracked
similarly after closing the previous file.

=head2 interval => NUM

Optional. The interval in seconds to poll the filehandle using C<stat(2)>
looking for size changes. A default of 2 seconds will be applied if not
defined.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $params->{interval} ||= 2;

   $self->SUPER::_init( $params );

   $self->start;
}

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{filename} ) {
      my $filename = delete $params{filename};
      $self->{filename} = $filename;
      $self->_reopen_file;
   }
   elsif( exists $params{handle} ) {
      $self->{handle} = delete $params{handle};
      $self->{last_stat} = stat $self->{handle};
   }

   foreach ( @STATS, "devino", "stat" ) {
      $self->{"on_${_}_changed"} = delete $params{"on_${_}_changed"} if exists $params{"on_${_}_changed"};
   }

   $self->SUPER::configure( %params );
}

sub _add_to_loop
{
   my $self = shift;

   if( !defined $self->{filename} and !defined $self->{handle} ) {
      croak "IO::Async::File needs either a filename or a handle";
   }

   return $self->SUPER::_add_to_loop( @_ );
}

sub _reopen_file
{
   my $self = shift;

   my $path = $self->{filename};

   open $self->{handle}, "<", $path or croak "Cannot open $path for reading - $!";

   $self->{last_stat} = stat $self->{handle};
}

sub on_tick
{
   my $self = shift;

   my $old = $self->{last_stat};
   my $new = stat( defined $self->{filename} ? $self->{filename} : $self->{handle} );

   my $any_changed;
   foreach my $stat ( @STATS ) {
      next if $old->$stat == $new->$stat;

      $any_changed++;
      $self->maybe_invoke_event( "on_${stat}_changed", $new->$stat, $old->$stat );
   }

   if( $old->dev != $new->dev or $old->ino != $new->ino ) {
      $self->maybe_invoke_event( on_devino_changed => $new, $old );
      $self->_reopen_file;
   }

   if( $any_changed ) {
      $self->maybe_invoke_event( on_stat_changed => $new, $old );
      $self->{last_stat} = $new;
   }
}

=head1 METHODS

=cut

=head2 handle

   $handle = $file->handle

Returns the filehandle currently associated with the instance; either the one
passed to the C<handle> parameter, or opened from the C<filename> parameter.

=cut

sub handle
{
   my $self = shift;
   return $self->{handle};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
