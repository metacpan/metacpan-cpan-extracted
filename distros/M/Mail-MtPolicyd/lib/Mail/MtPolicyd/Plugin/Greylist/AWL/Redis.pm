package Mail::MtPolicyd::Plugin::Greylist::AWL::Redis;

use Moose;

# ABSTRACT: backend for redis greylisting awl storage
our $VERSION = '2.05'; # VERSION

use Time::Seconds;

extends 'Mail::MtPolicyd::Plugin::Greylist::AWL::Base';

with 'Mail::MtPolicyd::Role::Connection' => {
  name => 'redis',
  type => 'Redis',
};

has 'prefix' => ( is => 'rw', isa => 'Str', default => 'awl-' );

sub _get_key {
  my ( $self, $domain, $ip ) = @_;
  return join(',', $self->prefix, $domain, $ip);
}

sub get {
	my ( $self, $sender_domain, $client_ip ) = @_;
  my $key = $self->_get_key($sender_domain, $client_ip);
	return $self->_redis_handle->get($key);
}

sub create {
	my ( $self, $sender_domain, $client_ip ) = @_;
  my $key = $self->_get_key($sender_domain, $client_ip);
  my $expire = ONE_DAY * $self->autowl_expire_days;
	$self->_redis_handle->set( $key, '1', 'EX', $expire );
	return;
}

sub incr {
	my ( $self, $sender_domain, $client_ip ) = @_;
  my $key = $self->_get_key($sender_domain, $client_ip);
  my $count = $self->_redis_handle->incr($key, sub {});
  my $expire = ONE_DAY * $self->autowl_expire_days;
	$self->_redis_handle->expire( $key, $expire, sub {});
  $self->_redis_handle->wait_all_responses;
	return;
}

sub remove {
	my ( $self, $sender_domain, $client_ip ) = @_;
  my $key = $self->_get_key($sender_domain, $client_ip);
	$self->_redis_handle->del($key);
	return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::Greylist::AWL::Redis - backend for redis greylisting awl storage

=head1 VERSION

version 2.05

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
