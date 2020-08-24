package Mail::MtPolicyd::Connection;

use Moose;

our $VERSION = '2.05'; # VERSION
# ABSTRACT: base class for mtpolicyd connection modules

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

sub init {
  my $self = shift;
  return;
}

sub reconnect {
  my $self = shift;
  return;
}

sub shutdown {
  my $self = shift;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Connection - base class for mtpolicyd connection modules

=head1 VERSION

version 2.05

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
