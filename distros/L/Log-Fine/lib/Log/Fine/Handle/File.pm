
=head1 NAME

Log::Fine::Handle::File - Output log messages to a file

=head1 SYNOPSIS

Provides logging to a file

    use Log::Fine;
    use Log::Fine::Handle::File;

    # Get a new logger
    my $log = Log::Fine->logger("foo");

    # Create a file handle (default values shown)
    my $handle = Log::Fine::Handle::File
        ->new( name => 'file0',
               mask => LOGMASK_EMERG | LOGMASK_ALERT | LOGMASK_CRIT | LOGMASK_ERR | LOGMASK_WARNING | LOGMASK_NOTICE | LOGMASK_INFO,
               dir  => "/var/log",
               file => "myapp.log",
               autoflush => 0 );

    # Register the handle
    $log->registerHandle($handle);

    # Log something
    $log->(INFO, "Opened new log handle");

=head1 DESCRIPTION

Log::Fine::Handle::File provides logging to a file.  Note that this
module will log messages to a specific file.  Support for dynamic
time-stamps in file names (e.g., C<myapp-080523.log>) is provided by
L<Log::Fine::Handle::File::Timestamp>.  Further features, such as log
file rotation I<a la> L<syslog> can be added by sub-classing this class.

=head2 Constructor Parameters

The following parameters can be passed to
Log::Fine::Handle::File->new():

=over

=item  * name

[optional] Name of this object (see L<Log::Fine>).  Will be autoset if
not specified.

=item  * mask

Mask to set the handle to (see L<Log::Fine::Handle>)

=item  * dir

Directory to place the log file

=item  * file

Name of the log file.  Note that if the given file is an absolute
path, then C<dir> will be ignored.

=item  * autoclose

[default: 0] If set to true, will close the filehandle after every
invocation of L</"msgWrite">.  B<NOTE:> will I<significantly> slow
down logging speed if multiple messages are logged at once.  Consider
autoflush instead

=item  * autoflush

[default: 0] If set to true, will force file flush after every write or
print (see L<FileHandle> and L<perlvar>)

=back

=cut

use strict;
use warnings;

package Log::Fine::Handle::File;

use base qw( Log::Fine::Handle );

use File::Basename;
use File::Spec::Functions;
use FileHandle;
use Log::Fine;

our $VERSION = $Log::Fine::Handle::VERSION;

=head1 METHODS

=head2 fileHandle

Getter for file handle.  If a file handle is not defined, then one
will be created.

Override this method if you wish to support
features such as time-stamped and/or rotating files.

=head3 Returns

A L<FileHandle> object

=cut

sub fileHandle
{

        my $self = shift;

        # Should we already have a file handle defined, return it
        return $self->{_filehandle}
            if (    defined $self->{_filehandle}
                and ref $self->{_filehandle}
                and UNIVERSAL::can($self->{_filehandle}, 'isa')
                and $self->{_filehandle}->isa("IO::File")
                and defined fileno($self->{_filehandle}));

        # Generate file name
        my $filename =
            ($self->{dir} =~ /\w/)
            ? catdir($self->{dir}, $self->{file})
            : $self->{file};

        # Otherwise create a new one
        $self->{_filehandle} = FileHandle->new(">> " . $filename);

        $self->_fatal("Unable to open log file $filename : $!\n")
            unless defined $self->{_filehandle};

        # Set autoflush if necessary
        $self->{_filehandle}->autoflush($self->{autoflush});

        return $self->{_filehandle};

}          # fileHandle()

=head2 msgWrite

See L<Log::Fine::Handle/msgWrite>

=cut

sub msgWrite
{

        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;
        my $skip = shift;

        # Grab a ref to our file handle
        my $fh = $self->fileHandle();

        # Should we have a formatter defined, then use that,
        # otherwise, just print the raw message
        $msg = $self->{formatter}->format($lvl, $msg, $skip)
            if defined $self->{formatter};

        print $fh $msg or $self->_error("Cannot write to file handle : $!");

        # Should {autoclose} be set, then close the file handle.  This
        # will force the creation of a new filehandle the next time
        # this method is called
        if ($self->{autoclose}) {
                $fh->close()
                    || $self->_error(
                                 sprintf("Unable to close filehandle to %s : %s", catdir($self->{dir}, $self->{file}), $!));
        }

        return $self;

}          # msgWrite()

# --------------------------------------------------------------------

##
# Initializes our object

sub _init
{

        my $self = shift;

        # Perform any necessary upper class initializations
        $self->SUPER::_init();

        # Default directory is the current directory unless file is an
        # absolute path
        if ($self->{file} =~ /^\/|^[A-Za-z]:\\/) {
                $self->{dir} = "";
        } elsif (not defined $self->{dir} or not -d $self->{dir}) {
                $self->{dir} = "./";
        }

        # Default file name is the name of the invoking program
        # suffixed with ".log"
        $self->{file} = basename($0) . ".log"
            unless defined $self->{file};

        # autoflush is disabled by default
        $self->{autoflush} = 0
            unless defined $self->{autoflush};

        # autoclose is disabled by default
        $self->{autoclose} = 0
            unless defined $self->{autoclose};

        return $self;

}          # _init()

##
# Called when this object is destroyed

sub DESTROY
{

        my $self = shift;

        # Close our filehandle if necessary.
        $self->{_filehandle}->close()
            if (    defined $self->{_filehandle}
                and ref $self->{_filehandle}
                and UNIVERSAL::can($self->{_filehandle}, 'isa')
                and $self->{_filehandle}->isa("IO::File")
                and defined fileno($self->{_filehandle}));

}          # DESTROY

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-fine at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Fine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Fine

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Fine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Fine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Fine>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Fine>

=back

=head1 AUTHOR

Christopher M. Fuhrman, C<< <cfuhrman at pobox.com> >>

=head1 SEE ALSO

L<perl>, L<Log::Fine>, L<Log::Fine::Handle>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008, 2010-2011, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Handle::File
