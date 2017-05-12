package Math::Homogeneous;

use strict;
use warnings;
use base 'Exporter';
use Clone qw/ clone /;
use overload
  '<>' => \&_get,
  fallback => 1;

our $VERSION = '0.03';

our @EXPORT = qw/ homogeneous /;
our @EXPORT_OK = qw/ homo /;

sub homogeneous {
  my $r = shift;
  my $array = ref $_[0] eq 'ARRAY' ? $_[0] : \@_;
  die if $r < 0;
  return [] if $r == 0;
  return [ map { [ $_ ] } @$array ] if $r == 1;
  my $homo = &homogeneous($r-1, $array);
  my $return = [];
  foreach my $h (@$homo) {
    for (@$array) {
      my $clone_h = clone $h;
      push @$clone_h, $_;
      push @$return, $clone_h;
    }
  }
  $return;
}

sub homo { homogeneous @_ }

sub new {
  my $class = shift;
  my $homo = homogeneous @_;
  my $iterator = {
    current  => 0,
    length   => scalar @$homo,
    iteratee => $homo,
  };
  bless($iterator, $class);
}

sub _next {
  my $self = shift;
  return undef unless $self->_has_next;
  $self->{iteratee}[$self->{current}++];
}

sub _has_next {
  my $self = shift;
  $self->{current} < $self->{length};
}

sub _get {
  my $self = shift;
  wantarray ? @{$self->{iteratee}} : $self->_next;
}

1;
__END__

=encoding utf-8

=head1 NAME

Math::Homogeneous - Perform homogeneous product

=head1 SYNOPSIS

=head2 Function
  
  use Math::Homogeneous;

  my @n = qw/ a b c /;
  my $homo = homogeneous(2, @n);
  for (@$homo) {
    print join(',', @$_) . "\n";
  }

=head3 Output
    
  a,a
  a,b
  a,c
  b,a
  b,b
  b,c
  c,a
  c,b
  c,c

=head2 Iterator

  use Math::Homogeneous;

  my @n = qw/ a b c /;
  my $itr = Math::Homogeneous->new(2, @n);
  
  while (<$itr>) {
    print join(',', @$_) . "\n";
  }

=head3 Output

  a,a
  a,b
  a,c
  b,a
  b,b
  b,c
  c,a
  c,b
  c,c

=head1 DESCRIPTION

Perform homogeneous product.

=head1 LICENSE

Copyright (C) hoto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hoto E<lt>hoto17296@gmail.comE<gt>

=cut

