package Mail::MtPolicyd::SessionCache::Base;

use Moose;

our $VERSION = '2.05'; # VERSION
# ABSTRACT: base class for session cache adapters

sub retrieve_session {
	my ($self, $instance ) = @_;
  return {};
}

sub store_session {
	my ($self, $session ) = @_;
	return;
}

sub init {
  my ( $self ) = @_;
  return;
}

sub shutdown {
  my ( $self ) = @_;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::SessionCache::Base - base class for session cache adapters

=head1 VERSION

version 2.05

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
