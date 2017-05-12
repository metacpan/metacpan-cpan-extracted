package HTTP::Server::Simple::Recorder;

our $VERSION = '0.03';

use warnings;
use strict;
use Carp;

use IO::File;

sub stdio_handle {
    my $self = shift;
    if (@_) {
	my $handle = $_[0];
	$self->{'_recorder_stdio_handle'} = $handle;
	
	my $serial = ++ $self->{'_recorder_serial'};
	my $prefix = $self->recorder_prefix;

	my $infile = "$prefix.$serial.in";
	my $outfile = "$prefix.$serial.out";

	my $in = IO::File->new("$infile", ">") or die "Couldn't open $infile: $!";
	$in->autoflush(1);
	my $out = IO::File->new("$outfile", ">") or die "Couldn't open $outfile: $!";
	$out->autoflush(1);

	$self->{'_recorder_stdin_handle'} = IO::Tee::Binmode->new($handle, $in);
	$self->{'_recorder_stdout_handle'} = IO::Tee::Binmode->new($handle, $out);
    } 
    return $self->{'_recorder_stdio_handle'};
} 

sub stdin_handle {
    my $self = shift;
    return $self->{'_recorder_stdin_handle'};
} 

sub stdout_handle {
    my $self = shift;
    return $self->{'_recorder_stdout_handle'};
}

sub recorder_prefix { "/tmp/http-server-simple-recorder"; } 

package IO::Tee::Binmode;

use base qw/IO::Tee/;

sub BINMODE {
    my $self = shift;
    my $ret = 1;
    if (@_) {
	for my $fh (@$self) { undef $ret unless binmode $fh, $_[0] }
    } else {
	for my $fh (@$self) { undef $ret unless binmode $fh }
    }
    return $ret;
}

sub READ {
    my $self = shift;
    my $bytes = $self->[0]->read(@_);
    # add the || 0 to silence warnings
    $bytes and $self->_multiplex_input(substr($_[0], $_[2] || 0, $bytes));
    $bytes;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

HTTP::Server::Simple::Recorder - Mixin to record HTTP::Server::Simple's sockets

=head1 SYNOPSIS

    package MyServer;
    use base qw/HTTP::Server::Simple::Recorder HTTP::Server::Simple::CGI/;
    
    sub recorder_prefix { "path/to/logs/record" }  # defaults to /tmp/http-server-simple-recorder

    # logs to path/to/logs/record.34244.1.in,
    #         path/to/logs/record.34244.1.out,
    #         path/to/logs/record.34244.2.in,
    #         path/to/logs/record.34244.2.out, etc, if 34244 is the PID of the server

=head1 DESCRIPTION

This module allows you to record all HTTP communication between an 
L<HTTP::Server::Simple>-derived server and its clients.  It is a mixin, so 
it doesn't itself subclass L<HTTP::Server::Simple>; you need to subclass from
both L<HTTP::Server::Simple::Recorder> and an actual L<HTTP::Server::Simple> subclass,
and L<HTTP::Server::Simple::Recorder> should be listed first.

Every time a client connects to your server, this module will open a pair of files and log
the communication between the file and server to these files.  Each connection gets a serial
number starting at 1.  The filename used is C<<$self->recorder_prefix>>, then a period,
then the connection serial number, then a period, then either "in" or "out".  
C<recorder_prefix> defaults to C</tmp/http-server-simple-recorder>, but you can override that
in your subclass.  For example, you might want to include the process ID.


=head1 DEPENDENCIES

L<IO::Tee>, L<HTTP::Server::Simple>.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-http-server-simple-recorder@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<HTTP::Server::Simple>, L<HTTP::Recorder>.

=head1 AUTHOR

David Glasser  C<< <glasser@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
