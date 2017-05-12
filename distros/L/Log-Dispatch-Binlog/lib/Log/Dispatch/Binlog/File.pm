#!/usr/bin/perl

package Log::Dispatch::Binlog::File;

use strict;

use base qw(
	Log::Dispatch::File
	Log::Dispatch::Binlog::Base
);

sub log_message {
	my ( $self, %p ) = @_;

	my $fh;

	if ( $self->{close} ) {
		$self->_open_file;
		$fh = $self->{fh};
		$self->_storable_print( $fh, \%p )
			or die "Cannot write to '$self->{filename}': $!";

		close $fh
			or die "Cannot close '$self->{filename}': $!";
	} else {
		$fh = $self->{fh};
		$self->_storable_print( $fh, \%p )
			or die "Cannot write to '$self->{filename}': $!";
	}
}

__PACKAGE__

__END__

=pod

=head1 NAME

Log::Dispatch::Binlog::File - A subclass of L<Log::Dispatch::File> that logs
with L<Storable>.

=head1 SYNOPSIS

	use Log::Dispatch::Binlog::File;

	my $output Log::Dispatch::Binlog::File->new(
		# Log::Dispatch::File options go here
	);

=head1 DESCRIPTION

Instead of printing messages this will store all of the params to
C<log_dispatch> using L<Storable/nstore_fd>.

=head1 SEE ALSO

L<Log::Dispatch::File>

=cut
