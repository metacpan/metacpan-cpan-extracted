package File::CreationTime;

use warnings;
use strict;
use File::Attributes qw(get_attribute set_attribute);

use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(creation_time);
our @EXPORT_OK = qw(creation_time);

=head1 NAME

File::CreationTime - Keeps track of file creation times

=head1 VERSION

Version 2.04

=cut

our $VERSION = '2.04';

=head1 SYNOPSIS

Keeps track of creation times on filesystems that don't normally
provide such information.

    use File::CreationTime;

    my $file = '/path/to/file';
    print "$file was created: ". creation_time($file). "\n";

=head1 EXPORT

=head2 creation_time

=head1 FUNCTIONS

=head2 creation_time

     creation_time('/path/to/file')

Returns the creation time of /path/to/file in seconds past the epoch.
Requires permission to modify extended filesystem attributes the first
time the function is called.  All subsequent invocations require read
access only.

=cut

sub creation_time {
    my $filename = shift;
    my $ATTRIBUTE = "creation_time";

    die "$filename does not exist" if !-e $filename;
    
    my $ctime;
    eval {
        if($^O =~ 'darwin'){
            eval {
                require MacOSX::File::Info;
                $ctime = MacOSX::File::Info->get($filename)->ctime();
            }
        }
        
        # fallback to attrs if the OS X method fails
        $ctime ||= get_attribute($filename, $ATTRIBUTE);
    };
    
    return $ctime if defined $ctime;
    
    # no ctime attr?  create one.
    my $mtime = (stat $filename)[9]; # 9 is mtime
    
    eval {
	set_attribute($filename, $ATTRIBUTE, $mtime);
    };
    warn "Failed to set attribute $ATTRIBUTE on $filename: $@" if $@;
    return $mtime;
}

=head1 ACCURACY

The algorithm used to determine the creation time is as follows.  The
first time creation_time is called, an extended filesystem attribute
called creation_time is created and is set to contain the time that
the file was most recently modified.  As such, if you have a file
that's several years old, then modify it, then call creation_time, the
file's creation time will obviously be wrong.  However, if you create
a file, call creation_time, wait several years, modify the file, then
call creation_time again, the result will be accurate.

On OS X, this method is not used.  Instead, the actual creation time
is provided via C<< MacOSX::File::Info->ctime >>.

=head1 DIAGNOSTICS

=head2 [path] does not exist

You passed [path] to creation_time, but it doesn't exist (or you can't
read it).

=head2 Failed to set attribute user.creation_time on [file]

Couldn't create the attribute for some reason.  Does your filesystem
support extended filesystem attributes?

=head1 SEE ALSO

L<File::Attributes|File::Attributes> handles storing the creation_time
attribute.

=head1 BUGS

I'd like to support OSes that actually give you the file creation
time.  As of version 2.04, OS X is supported in this way.  If you know
how to make this work on your OS, tell me how or send me a patch.

Other comments and patches are always welcome.

=head2 REPORTING

Please report any bugs or feature requests to
C<bug-file-creationtime@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-creationTime>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway AT cpan.org> >>.

=head1 CONTRIBUTORS

Dave Cardwell added OS X support.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jonathan T. Rockway.

This program is Free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of File::CreationTime
