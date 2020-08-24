package Mail::MtPolicyd::Plugin::Greylist::AWL::Base;

use Moose;

# ABSTRACT: base class for grelisting AWL storage backends
our $VERSION = '2.05'; # VERSION

has 'autowl_expire_days' => ( is => 'rw', isa => 'Int', default => 60 );

sub init {
  my $self = shift;
  return;
}

sub get {
	my ( $self, $sender_domain, $client_ip ) = @_;
  die('not implemented');
}

sub create {
	my ( $self, $sender_domain, $client_ip ) = @_;
  die('not implemented');
}

sub incr {
	my ( $self, $sender_domain, $client_ip ) = @_;
  die('not implemented');
}

sub remove {
	my ( $self, $sender_domain, $client_ip ) = @_;
  die('not implemented');
}

sub expire { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::Greylist::AWL::Base - base class for grelisting AWL storage backends

=head1 VERSION

version 2.05

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
