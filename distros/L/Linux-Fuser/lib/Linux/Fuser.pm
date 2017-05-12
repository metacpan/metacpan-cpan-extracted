#*****************************************************************************
#*                                                                           *
#*                          Gellyfish Software                               *
#*                                                                           *
#*                                                                           *
#*****************************************************************************
#*                                                                           *
#*      PROGRAM     :  Linux::Fuser                                          *
#*                                                                           *
#*      AUTHOR      :  JNS                                                   *
#*                                                                           *
#*      DESCRIPTION :  Provide an 'fuser' like facility in Perl              *
#*                                                                           *
#*                                                                           *
#*****************************************************************************
#*                                                                           *
#*      $Id$
#*                                                                           *
#*****************************************************************************

package Linux::Fuser;

=head1 NAME

Linux::Fuser - Determine which processes have a file open

=head1 SYNOPSIS

  use Linux::Fuser;

  my $fuser = Linux::Fuser->new();

  my @procs = $fuser->fuser('foo');

  foreach my $proc ( @procs )
  {
    print $proc->pid(),"\t", $proc->user(),"\n",@{$proc->cmd()},"\n";
  }

=head1 DESCRIPTION

This module provides information similar to the Unix command 'fuser' about
which processes have a particular file open.  The way that this works is
highly unlikely to work on any other OS other than Linux and even then it
may not work on other than 2.2.* kernels. Some features may not work
correctly on kernel versions older than 2.6.22

It should also be borne in mind that this may not produce entirely accurate
results unless you are running the program as the Superuser as the module
will require access to files in /proc that may only be readable by their
owner.

=head2 METHODS

=over 4

=cut

use strict;

use vars qw(
            $VERSION
            @ISA
           );

$VERSION = '1.6';

=item new

The constructor of the object. It takes no arguments and returns a blessed
reference suitable for calling the methods on.

=cut

sub new
{
    my ( $proto, @args ) = @_;

    my $class = ref($proto) || $proto;

    my $self = {};

    bless $self, $class;

    return $self;

}

=item fuser SCALAR $file

Given the name of a file it will return a list of Linux::Fuser::Procinfo
objects, one for each process that has the file open - this will be the
empty list if no processes have the file open or undef if the file doesnt
exist.

=cut

sub fuser
{
    my ( $self, $file, @args ) = @_;

    return () unless -f $file;

    my @procinfo = ();

    my ( $dev, $ino, @ostuff ) = stat($file);

    opendir PROC, '/proc' or die "Can't access /proc - $!\n";

    my @procs = grep /^\d+$/, readdir PROC;

    closedir PROC;

    foreach my $proc (@procs)
    {
        opendir FD, "/proc/$proc/fd" or next;

        my @fds = map { ["/proc/$proc/fd/$_",$_] } grep /^\d+$/, readdir FD;

        closedir FD;

        foreach my $fd_data (@fds)
        {
            my $fd    = $fd_data->[0];
            my $fd_no = $fd_data->[1];

            if ( my @statinfo = stat $fd )
            {
                if ( ( $dev == $statinfo[0] ) && ( $ino == $statinfo[1] ) )
                {
                   push @procinfo,Linux::Fuser::Procinfo->new($proc, $fd_data);
                }
            }
        }
    }
    return @procinfo;
}

1;

package Linux::Fuser::Procinfo;

=back

=head2 PER PROCESS METHODS

The fuser() method will return a list of objects of type Linux::Fuser::Procinfo
which itself has methods to return information about the process.

=over 2

=item user

The login name of the user that started this process ( or more precisely
that owns the file descriptor that the file is open on ).

=item pid

The process id of the process that has the file open.

=item cmd

The command line of the program that opened the file.  This actually returns
a reference to an array containing the individual elements of the command
line.

=item filedes

A Linux::Fuser::FileDescriptor object that has details of the file as
the process has it opened - see below.

=back


=cut

use strict;
use Carp;

use vars qw($AUTOLOAD);

sub new
{
   my ( $class, $pid, $fd_data ) = @_;

   my $fd    = $fd_data->[0];
   my $fd_no = $fd_data->[1];

   my $user = getpwuid( ( lstat($fd) )[4] );

   my @cmd = ('');

   if ( open CMD, "/proc/$pid/cmdline" )
   {
      chomp( @cmd = <CMD> );
   }

   my $filedes = Linux::Fuser::FileDescriptor->new($pid, $fd_no);

   my $procinfo = {
                   pid     => $pid,
                   user    => $user,
                   cmd     => \@cmd,
                   filedes => $filedes
                  };

   bless $procinfo, $class;

   return $procinfo;

}

sub AUTOLOAD
{
    my ( $self, @args ) = @_;

    no strict 'refs';

    ( my $method = $AUTOLOAD ) =~ s/.*://;

    return if $method eq 'DESTROY';

    if ( exists $self->{$method} )
    {
        *{$AUTOLOAD} = sub {
            my ( $self, @args ) = @_;
            return $self->{$method};
        };
    }
    else
    {
        my $pack = ref($self);
        croak "Can't find method $method via package $self";
    }

    goto &{$AUTOLOAD};

}

1;

package Linux::Fuser::FileDescriptor;

=head2 Linux::Fuser::FileDescriptor

This is returned by the filedes method of the Linux::Fuser::Procinfo and
contains the information about the file descriptor that the process has the
file open under. 

The information which this is based on is only available from Linux Kernel
version 2.6.22 onwards so will not be available on earlier kernels (except
the 'fd'.)

It has the following methods (though future versions of the Linux Kernel may
provide different or fuller information via /proc/$pid/fdinfo):

=over 2

=item fd

The file descriptor that this file is opened under - this will be unique
within a process (if a file is opened more than once by a process) but not
within the system.

=item flags

The flags with which the file was opened (by open or creat) as a long integer.

=item pos

The location (in bytes) of the file pointer within the file.

=back

=cut

use strict;
use warnings;
use Carp;

use vars qw($AUTOLOAD);

sub new
{
   my ( $class, $pid, $fd_no ) = @_;


   my $self = {
                fd => $fd_no
              };

   if ( open FDINFO,'<',"/proc/$pid/fdinfo/$fd_no" )
   {
      while(my $fd_info = <FDINFO>)
      {
         chomp($fd_info);
         my ($key, $value ) = split /:\s+/, $fd_info;
         $self->{$key} = $value;
      }
   }
   else
   {
      $self->{'pos'} = undef;
      $self->{'flags'} = undef;
   }

   return bless $self, $class;
}

sub AUTOLOAD
{
    my ( $self, @args ) = @_;

    no strict 'refs';

    ( my $method = $AUTOLOAD ) =~ s/.*://;

    return if $method eq 'DESTROY';

    if ( exists $self->{$method} )
    {
        *{$AUTOLOAD} = sub {
            my ( $self, @args ) = @_;
            return $self->{$method};
        };
    }
    else
    {
        my $pack = ref($self);
        croak "Can\'t find method $method via package $self";
    }

    goto &{$AUTOLOAD};

}

1;
__END__

=head2 EXPORT

None.

=head1 AUTHOR

Jonathan Stowe, E<lt>jns@gellyfish.co.ukE<gt>

=head1 SUPPORT

Patches are always welcome against the latest code at
https://github.com/jonathanstowe/Linux-Fuser

=head1 COPYRIGHT AND LICENSE

Please see the README file in the source distribution.

=head1 SEE ALSO

L<perl>. L<proc(5)>

=cut
