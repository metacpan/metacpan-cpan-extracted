package MLDBM::Easy;

use warnings;

@ISA = 'MLDBM';
$VERSION = '0.01';

my %cache;

sub import {
  my $pkg = shift;
  require MLDBM;
  MLDBM->import(@_);
}


sub FETCH {
  my ($self, $key) = @_;
  my $ret = $self->{SR}->deserialize($self->{DB}->FETCH($key));
  return $cache{$self,$key} if $cache{$self,$key};

  if (ref($ret) eq "HASH") {
    tie my(%h), 'MLDBM::Easy::Hash', $self, $key, $ret;
    return $cache{$self,$key} = \%h;
  }

  if (ref($ret) eq "ARRAY") {
    tie my(@a), 'MLDBM::Easy::Array', $self, $key, $ret;
    return $cache{$self,$key} = \@a;
  }

  if (ref($ret) eq "SCALAR") {
    tie my($s), 'MLDBM::Easy::Scalar', $self, $key, $ret;
    return $cache{$self,$key} = \$s;
  }
}


sub STORE {
  my ($self, $key, $value) = @_;
  $value = $self->{SR}->serialize($cache{$self,$key});
  $self->{DB}->STORE($key, $value);
}


package MLDBM::Easy::Hash;
use Tie::Hash;
@ISA = 'Tie::StdHash';

sub TIEHASH {
  my ($class, $mldbm, $key, $href) = @_;
  my $self = bless $href, $class;
  $cache{$self} = [$mldbm, $key];
  return $self;
}

sub STORE {
  my ($self, $key, $value) = @_;
  $self->{$key} = $value;
  $cache{$self}->[0]->STORE($cache{$self}->[1], $self);
}


package MLDBM::Easy::Array;
use Tie::Array;
@ISA = 'Tie::StdArray';

sub TIEARRAY {
  my ($class, $mldbm, $key, $href) = @_;
  my $self = bless $href, $class;
  $cache{$self} = [$mldbm, $key];
  return $self;
}

sub STORE {
  my ($self, $idx, $value) = @_;
  $self->[$idx] = $value;
  $cache{$self}->[0]->STORE($cache{$self}->[1], $self);
}


package MLDBM::Easy::Scalar;
use Tie::Scalar;
@ISA = 'Tie::StdScalar';

sub TIESCALAR {
  my ($class, $mldbm, $key, $sref) = @_;
  my $self = bless $sref, $class;
  $cache{$self} = [$mldbm, $key];
  return $self;
}

sub STORE {
  my ($self, $value) = @_;
  $$self = $value;
  $cache{$self}->[0]->STORE($cache{$self}->[1], $self);
}


1;

__END__

=head1 NAME

MLDBM::Easy - Provides NON-piecemeal access to MLDBM files

=head1 SYNOPSIS

  use MLDBM::Easy;  # as a drop-in for MLDBM

=head1 DESCRIPTION

This module allows you to work with multi-dimensional databases, just like
L<MLDBM>, but it does work behind the scenes to allow you to treat the
multi-dimensional database like a normal data structure.  Basically, you don't
need to use the piecemeal access that L<MLDBM> required:

  # old and busted
  my $record = $db{some_key};
  $record->[2] += 100;
  $db{some_key} = $record;

  # new hotness
  $db{some_key}[2] += 100;

Of course, with this convenience comes a loss of speed.  Deal with it.

=head1 SEE ALSO

Check L<MLDBM> for all other documentation.

=head1 AUTHOR

Jeff C<japhy> Pinyan, E<lt>japhy@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by japhy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
