#!/usr/bin/perl

package Log::Dispatch::Binlog::Handle;

use strict;

use base qw(
	Log::Dispatch::Handle
	Log::Dispatch::Binlog::Base
);

sub log_message {
	my ( $self, %p ) = @_;

	$self->_storable_print( $self->{handle}, \%p )
        or die "Cannot write to handle: $!";
}

__PACKAGE__

__END__

=pod

=head1 NAME

Log::Dispatch::Binlog::Handle - A subclass of L<Log::Dispatch::Handle> that
logs with L<Storable>.

=head1 SYNOPSIS

	use Log::Dispatch::Binlog::Handle;

	my $output Log::Dispatch::Binlog::Handle->new(
		# Log::Dispatch::Handle options go here
	);

=head1 DESCRIPTION

Instead of printing messages this will store all of the params to
C<log_dispatch> using L<Storable/nstore_fd>.

=head1 SEE ALSO

L<Log::Dispatch::Handle>

=cut
