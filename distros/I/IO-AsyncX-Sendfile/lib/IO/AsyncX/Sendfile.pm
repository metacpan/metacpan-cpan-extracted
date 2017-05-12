package IO::AsyncX::Sendfile;
# ABSTRACT: sendfile support for IO::Async
use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

IO::AsyncX::Sendfile - adds support for L<Sys::Sendfile> to L<IO::Async::Stream>

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 $stream->sendfile(
  file => 'somefile',
 )->on_done(sub {
  $stream->close;
 });

=head1 DESCRIPTION

B<NOTE>: This is currently a proof-of-concept, the actual API may vary in later
versions. Eventually this functionality will be incorporated into the generic  async
filehandling API, so this module is provided as a workaround in the interim.

Provides a L</sendfile> method on L<IO::Async::Stream>.

=cut

use Sys::Sendfile;
use Fcntl qw(SEEK_SET SEEK_END);
use Future;
use IO::Async::Stream;

=head1 METHODS

Note that these methods are injected directly into L<IO::Async::Stream>.

=cut

=head2 sendfile

Write the contents of the file directly to the socket without reading it
into memory first (using the kernel's sendfile call if available).

Called with the following named parameters:

=over 4

=item * file - if defined, this will be used as the filename to open

=item * fh - if defined, we'll use this as the filehandle

=item * length - if defined, send this much data from the file (default is
'everything from current position to end') 

=back

Returns a L<Future> which will be resolved with the number of bytes written
when successful.

Example usage:

 my $listener = $loop->listen(
     addr => {
         family => 'unix',
         socktype => 'stream',
         path => 'sendfile.sock',
     },
     on_stream => sub {
         my $stream = shift;
         $stream->configure(
             on_read => sub {
                 my ($self, $buffref, $eof) = @_;
                 $$buffref = '';
                 return 0;
             },
         );
		 if('send one file') {
             $stream->sendfile(
                 file => 'test.dat',
             )->on_done(sub {
                 warn "File send complete: @_\n";
                 $stream->close;
             });
         } else {
             $stream->sendfile(file => 'first.dat');
             $stream->sendfile(file => 'second.dat');
             $stream->write('EOF', on_flush => sub { shift->close });
		 }
         $loop->add($stream);
     }
 );

If the sendfile call fails, the returned L<Future> will fail with the
string exception from $! as the failure reason, with sendfile => numeric $!,
remaining bytes as the remaining details:

 ==> ->fail("Some generic I/O error", "sendfile", EIO, 60000)

=cut

*IO::Async::Stream::sendfile = sub {
	my $self = shift;
	my %args = @_;
	die "Stream must be added to loop first" unless $self->loop;

	if(defined $args{file}) {
		open $args{fh}, '<', $args{file} or die "Could not open " . $args{file} . " for input - $!";
		binmode $args{fh};
	}
	die 'No file?' unless my $fh = delete $args{fh};

	# Work out how much we need to write
	my $total = my $remaining = $args{length};
	unless(defined $total) {
		my $pos = tell $fh;
		seek $fh, 0, SEEK_END or die "Unable to seek - $!";
		$total = $remaining = tell $fh;
		seek $fh, $pos, SEEK_SET or die "Unable to seek - $!";
	}
	my $f = $self->loop->new_future;

	$self->write(sub {
		my $stream = shift;
		return unless $remaining;

		unless($remaining > 0) {
			$f->fail(EOF => "Attempt to write past EOF, remaining bytes: " . $remaining);
			return;
		}

		if(my $written = sendfile $stream->write_handle, $fh, $remaining) {
			$remaining -= $written;
			return ''; # empty string => call us again please
		}

		$f->fail("$!", sendfile => 0 + $!, $remaining);
		return;
	}, on_flush => sub {
		$f->done($total) unless $f->is_ready;
	});
	return $f;
};


1;

__END__

=head1 SEE ALSO

L<Sys::Sendfile>

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
