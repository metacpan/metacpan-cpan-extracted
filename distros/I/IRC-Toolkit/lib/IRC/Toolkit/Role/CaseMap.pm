package IRC::Toolkit::Role::CaseMap;
$IRC::Toolkit::Role::CaseMap::VERSION = '0.092002';
use strictures 2;
use Carp;

use IRC::Toolkit::Case;


use Role::Tiny;
requires 'casemap';

sub lower {
  my ($self, $val) = @_;
  confess "lower() called without a value" unless defined $val;
  lc_irc $val, $self->casemap
}

sub upper {
  my ($self, $val) = @_;
  confess "upper() called without a value" unless defined $val;
  uc_irc $val, $self->casemap
}

sub equal {
  confess 'equal() expects two values' unless @_ == 3;
  my ($self, $one, $two) = @_;
  my $cmap = $self->casemap;
  uc_irc($one, $cmap) eq uc_irc($two, $cmap)
}

1;

=pod

=head1 NAME

IRC::Toolkit::Role::CaseMap - Role for classes that track IRC casemapping

=head1 SYNOPSIS

  package MyIRC;
  use Moo;

  has casemap => (
    is  => 'rw',
    default => sub { 'rfc1459' },
    coerce  => sub { lc $_[0] },
  );

  with 'IRC::Toolkit::Role::CaseMap';

  sub mymeth {
    my ($self, $nickname, $one, $two) = @_;

    my $lowered = $self->lower( $nickname );
    my $uppered = $self->upper( $nickname );

    if ( $self->equal( $one, $two ) ) {
      ...
    }
  }

=head1 DESCRIPTION

A L<Role::Tiny> role that provides convenient helper methods for classes that
track IRC casemapping, such as IRC client libraries.

This role C<requires> a B<casemap> attribute that returns one of 'rfc1459',
'ascii', or 'strict-rfc1459' -- see L<IRC::Toolkit::Case> for details on IRC 
casemap issues.

=head2 lower

Returns the IRC-lowercased string.

=head2 upper

Returns the IRC-uppercased string.

=head2 equal

Expects two strings; returns true if they are equal per the current B<casemap>
rules. Returns empty list if the strings do not match.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
