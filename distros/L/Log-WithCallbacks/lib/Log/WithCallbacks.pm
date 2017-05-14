package Log::WithCallbacks;

use strict;
use Carp;
use Symbol;
use Fcntl;
use IO::File;

use vars qw( $VERSION );

$VERSION = '1.00';

my $standard_format = sub {
    my $message = shift;

    chomp $message;	# Clean up any accidental double lines.
    return scalar localtime(time) . ": $message\n";
};

sub new { 
    my $class  = shift;
    my $file   = shift || croak 'Must supply a filename';
    my $format = shift;

    my $self = {
	LOGFILE	    => IO::File->new(),
	file	    => $file,
	'format'    => '',
	'status'    => 'closed',
	mode	    => 'append',
    };

    $self->{LOGFILE}->autoflush(1);
    bless $self, $class;

    # Set format to default if no format is provided.
    $format = defined $format ? $format : 'standard';
    $self->format($format) or $self->format('standard');
	
    return $self;
}
    
sub open {
    my $self=shift;
    my $mode= shift || $self->mode() || 'append';
    my $format = shift;
    
    $self->mode($mode);
    $self->format($format);
    $self->_setStatus('opening');
    
    # Assemble mode
    my $fcntl_mode =  O_WRONLY | O_CREAT;
    
    if ($self->mode eq 'append') {
        $fcntl_mode |= O_APPEND;
    } elsif ($self->mode eq 'overwrite') {
        $fcntl_mode |= O_TRUNC;
    } else {
	my $badmode = $self->mode;
	croak "Illegal mode: cannot open logfile in mode $badmode"
    }
    # Open IO::File object.
    $self->{LOGFILE}->open($self->{file}, $fcntl_mode)   
        or croak "Unable to open logfile $self->{file}: $!";

    $self->_setStatus('open');
}

sub close {
    my $self = shift;

    carp('Cannot close a logfile that is not open'), return 0 
	unless $self->status eq 'open';
    
    $self->_setStatus('closing');

    close $self->{LOGFILE} or croak "Unable to close logfile: $!";

    $self->_setStatus('closed');
    return 'closed';
}

sub exit {
    my $self = shift;

    my $error_code = shift;
    my ($message) = @_;

    $self->entry("Script terminating - $error_code", @_);

    $self->entry( @_ );
    
    $!=$error_code;
    croak "$message";
}

sub entry {
    my $self = shift;

    my $message = shift;
    my $format  = shift;

    carp "Format '$format' is not a code reference or string literal 'standard'." 
        if ( 
            ( $format                ) && 
            ( ref($format) ne 'CODE' ) && 
            ( $format ne 'standard'  ) 
        );

    $format = $standard_format if $format eq 'standard';
    
    $format = $self->{'format'} unless ref($format) eq 'CODE';

    carp "Cannot log entry unless log status is 'open'"
	if $self->status ne 'open';
    
    my $string = $format->($message);
    print {$self->{LOGFILE}} $string;

    return $string;
}

sub status {
    my $self = shift;

    return $self->{status};
}

sub mode {
    my $self = shift;
    my $mode = shift;

    my %mode;
    @mode{qw(overwrite append)} = (1) x 2;

    if ($mode) {
	if (exists $mode{$mode}) {
	    if ($self->status eq 'closed') {
		$self->{mode} = $mode;
	    } 
	    elsif ($self->{mode} ne $mode) {
		carp "Can only set mode when logfile is closed";
	    }
	} else {
	    carp "Illegal mode $mode, mode remains set to $self->{mode}";
	    return 0;
	}
    }

    return $self->{mode};
}

sub format {
    my $self = shift;
    my $format = shift || '';

    if ($format eq 'standard') {
	$self->{'format'} = $standard_format;
    }
    elsif ($format) {
	unless ( ref $format eq 'CODE' ) {
	    croak "Format must be a code reference or 'standard'";
	    return 0;
	}
	$self->{'format'} = $format;
    }
    
    return $self->{'format'};
}

sub _setStatus {
    my $self = shift;
    my $status = shift;

    my %status;
    @status{qw(open closed opening closing)} = (1) x 4;
    
    croak "Illegal logfile status $status" unless exists $status{$status};
    $self->{'status'} = $status;
}

1;
__END__

=head1 NAME

Log::WithCallbacks - A simple, object oriented logfile management library.

=head1 SYNOPSIS

  use Log::WithCallbacks;
  
  my $logfile = '/var/log/perl/mylog';
  
  # Basic usage
  
  my $log = Log::WithCallbacks->new( $logfile );
  $log->open();

  $log->entry("Stuff happened");
  $log->exit(23, "Bad stuff happened and I am shutting down");
  $log->close();
  
  
  # Advanced functionality
  
  my $errors = Log::WithCallbacks->new( $logfile, sub { return "OOPS: $_[0]\n" } );
  
  $log->entry($hash_ref, sub { Dumper @_ });
  $log->exit(5, "Bad stuff happened and I am shutting down", 'standard' });
  
  my $status = $log->status();
  my $mode = $log->mode('overwrite');
  my $format = $log->format( sub {
      my $message = shift;
      return "\t$message\n";
  } );
  

=head1 DESCRIPTION

Log::WithCallbacks is intended to simplify aspects of managing a logfile.  It uses object oriented interface that is both simple and flexible.  This module will not pollute your namespace, it does not export anything.

=head2 METHODS

=head3 new 

=over

=item $log_obj = new( $path, [$format] )

This method is the class' constructor.  You must provide a filename for the logfile; while it is best to use a fully qualified name, any name acceptable to C<open> will do.  It is also possible to pass in a subroutine reference to set the default format routine.  The default format routine will be used to process the message parameters to all calls to C<entry> and C<exit>.  See L<"format"> for more information on format routines.

=back

=head3 open

=over

=item open( [$mode, $format] )

Opens a filehandle to the logfile and sets the status to b<open>.  The method has two optional arguments, C<$mode> and C<$format>.  C<$mode> can be either B<append> or B<overwrite>, it controls whether the filehandle will append to or overwrite the file it opens.  C<$format> provides another opportunity to set the default format routine, see L<"new"> and L<"format"> for more information.  This method will die if it cannot open the filehandle, if this is not acceptable, you will need to use C<eval {}> to trap the exception.

=back

=head3 close

=over

=item close()

Closes an open logfile and sets the status to b<closed>.  This method will die if it cannot close the filehandle, if this is not acceptable, you will need to use C<eval {}> to trap the exception.

=back

=head3 entry

=over

=item entry( $message, [$format] )

Writes C<$message> to the logfile, after passing it through the format routine.  If the optional C<$format> argument is sent, the routine provided will be used.  Otherwise the default format routine will be used.  C<$message> is usually a string, but can be just about anything, depending on the format routine that will process it.  See L<"format"> for more information on format routines.

=back

=head3 exit

=over

=item exit( $status_code, $message, [$format] )

Calls C<entry($message, $format)>, then sets C<$!> to C<$status_code> (which must be numeric) and terminates the script. See L<"entry"> for more information.

=back

=head3 status

=over

=item $string = status()

Returns the current status of the logfile object.  Should only return B<closed> or B<open>.  If an untrapped error has occurred, it may return a status of B<opening> or B<closing>.

=back

=head3 mode

=over

=item $string = entry( [$mode] )

Gets or sets the mode of the logfile object.  Allowed modes are B<append> and B<overwrite>.  The mode can only be changed when the object's status is B<closed>.  Returns the mode as a string, or 0 on a failed attempt to set the mode. 

=back

=head3 format

=over

=item $code_ref = format( [$format] )

Gets or sets the object's default format routine.  Returns a reference to the default format routine, or B<0> on a failed attempt to set the format routine.  Can take either the string B<standard> or a code reference as an argument.  If $format is B<standard>, then the standard formatter that is built into the module will be used.

=over

=item Format Routines

Format routines are used to process all messages that are logged.  This feature is what makes this module particularly flexible.  A format routine takes one argument, usually a string, and returns a list suitable for C<print> to process.

 # Example Format Routines
 
 # Standard Default Routine
 $log->format( sub {
    my $message = shift;
    chomp $message;	# Clean up any accidental double lines.
    return scalar time . ": $message\n";
 } );
 
 # Do nothing
 $log->format( sub { return @_ } );
  
 # Using Data::Dumper to look inside a few variables
 $log->entry( [$hash_ref, $array_ref],  sub { Dumper @_ } );

 # Use a closure to generate line numbers
 {  my $counter = 1;

    $log->format( sub {
	my $message = shift;
	chomp $message;

	return sprintf( "%-3.3d - $message\n", $counter++ );
    }
 }

=back

=back

=head1 BUGS

No known bugs exist.  Tainting and better validation of file names should be put in place before this library should handle untrusted input.  Of particular concern is the C<path> argument to the contstructor, as this is passed to the I<open> builtin. 

=head1 AUTHOR

Mark Swayne, E<lt>mark.swayne@chater.netE<gt>
Copyright 2002, Mark Swayne
Copyright 2005, Zydax, LLC.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
