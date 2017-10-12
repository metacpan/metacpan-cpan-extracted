package Directory::Scanner::API::Stream;
# ABSTRACT: Streaming directory iterator abstract interface

use strict;
use warnings;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

sub head;

sub is_done;
sub is_closed;

sub close;
sub next;

sub clone; # ( $dir => Path::Tiny )

## ...

sub flatten {
	my ($self) = @_;
	my @results;
	while ( my $next = $self->next ) {
		push @results => $next;
	}
	return @results;
}

## ...

# shhh, I shouldn't do this
sub _log {
	my ($self, @msg) = @_;
    warn( @msg, "\n" );
    return;
}

1;

__END__

=pod

=head1 NAME

Directory::Scanner::API::Stream - Streaming directory iterator abstract interface

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This is a simple API role that defines what a stream object
can do.

=head1 METHODS

=head2 C<next>

Get the next item in the stream.

=head2 C<head>

The value currently being processed. This is always the
same as the last value returned from C<next>.

=head2 C<is_done>

This indicates that the stream has been exhausted and
that there is no more values to come from next.

This occurs *after* the last call to C<next> that
returned nothing.

=head2 C<close>

This closes a stream and any subsequent calls to C<next>
will throw an error.

=head2 C<is_closed>

This indicates that the stream has been closed, usually
by someone calling the C<close> method.

=head2 C<clone( ?$dir )>

This will clone a given stream and can optionally be
given a different directory to scan.

=head2 C<flatten>

This will take a given stream and flatten it into an
array.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
