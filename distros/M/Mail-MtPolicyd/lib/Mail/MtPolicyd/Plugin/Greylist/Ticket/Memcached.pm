package Mail::MtPolicyd::Plugin::Greylist::Ticket::Memcached;

use Moose;

# ABSTRACT: greylisting ticket storage backend for memcached
our $VERSION = '2.05'; # VERSION

extends 'Mail::MtPolicyd::Plugin::Greylist::Ticket::Base';

with 'Mail::MtPolicyd::Role::Connection' => {
  name => 'memcached',
  type => 'Memcached',
};

sub get {
	my ( $self, $r, $sender, $ip, $rcpt ) = @_;
	my $key = $self->_get_key($sender, $ip, $rcpt);
	if( my $ticket = $self->_memcached_handle->get( $key ) ) {
		return( $ticket );
	}
	return;
}

sub is_valid {
	my ( $self, $ticket ) = @_;
	if( time > $ticket ) {
		return 1;
	}
	return 0;
}

sub remove {
	my ( $self, $r, $sender, $ip, $rcpt ) = @_;
	my $key = $self->_get_key($sender, $ip, $rcpt);
	$self->_memcached_handle->delete( $key );
	return;
}

sub create {
	my ( $self, $r, $sender, $ip, $rcpt ) = @_;
	my $ticket = time + $self->min_retry_wait;
	my $key = $self->_get_key($sender, $ip, $rcpt);
	$self->_memcached_handle->set( $key, $ticket, $self->max_retry_wait );
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::Greylist::Ticket::Memcached - greylisting ticket storage backend for memcached

=head1 VERSION

version 2.05

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
