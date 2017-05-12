package HTTP::Server::Simple::Dispatched::Request;
use HTTP::Request;
use base qw(HTTP::Request);

=pod

=head1 DESCRIPTION

This built by HTTP::Server::Simple::Dispatched to avoid reading the
entity-body of a message if it is never asked for.  You likely don't want to
use it directly

=head1 METHODS

=head2 new

Because it's convenient, any field you can set on a normal Request object can be passed as a keyword parameter here, and the normal constructor with positional arguments is ignored.  In addition, a handle parameter is passed in - this is the file handle from which to read the entity-body of the request.  A Content-Length header must be present, or content will be empty.  This is not standards compliant at all, and will likely change in future versions.  

=cut

sub new {
	my ($class, %opts) = @_;
	my $self = $class->SUPER::new();

	foreach my $arg (keys %opts) {
		if (my $setter = $self->can($arg)) {
			$setter->($self, $opts{$arg});
			delete $opts{$arg};
		}
	}

	$self->{_handle} = $opts{handle};
	return bless $self, $class;
}

=head2 read_content

This forces the content to be read from the provided filehandle: this should be called if you're planning on storing the request, as the filehandle will become invalid after the request is handled.

=cut

sub read_content {
	my $self = shift;
	my $handle = (delete $self->{_handle}) || return;
	my $content = q();

	my $to_read = $self->content_length || return;
	while (my $bytes_read = sysread($handle, my $buffer, $to_read)) {
		$to_read -= $bytes_read;
		$content .= $buffer;
	}
	$self->content_length($self->content_length - $to_read);
	$self->content($content);
	delete $self->{_handle};
}

=head2 content

=cut

sub content {
	my $self = shift;	
	$self->read_content;	
	$self->SUPER::content(@_);
}

=head2 content_ref

These both force read_content to be called, but otherwise are identical to the
parent class's.

=cut

sub content_ref {
	my $self = shift;	
	$self->read_content;	
	$self->SUPER::content_ref(@_);
}

1;

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-http-server-simple-dispatched at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Server-Simple-Dispatched>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<HTTP::Request>, L<HTTP::Server::Simple::Dispatched>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul Driver, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
