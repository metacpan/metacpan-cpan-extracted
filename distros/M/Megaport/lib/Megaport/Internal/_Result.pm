package Megaport::Internal::_Result;

use 5.10.0;
use strict;
use warnings;

use Carp qw(croak cluck);
use List::Util qw(first);
use Megaport::Internal::_Obj;

use Class::Tiny qw(client errstr), {
  _data => {}
};

sub BUILD {
  my ($self, $args) = @_;

  croak __PACKAGE__ . '->new: client not passed to constructor' unless $self->client;

  my $data = $self->client->request($self->_request->{method} => $self->_request->{path});

  if ($data) {
    my %list;
    foreach (@{$data}) {
      $list{$_->{ $self->_request->{pkey} }} = Megaport::Internal::_Obj->new(%{$_});
    }

    $self->_data(\%list);
  }
}

sub get {
  my ($self, %search) = @_;

  if ($search{id} && exists $self->_data->{$search{id}}) {
    return $self->_data->{$search{id}};
  }

  my $needle = first {
    foreach my $k (keys %search) {
      last unless exists $_->{$k};
      return $_ if $_->{$k} eq $search{$k};
    }
  } values %{$self->_data};

  return $needle;
}

sub list {
  my ($self, %search) = @_;
  my @result;

  if (!%search) {
    @result = values %{$self->_data};
  }
  else {
    foreach my $item (values %{$self->_data}) {
      foreach my $k (keys %search) {
        if (ref $search{$k} eq 'Regexp') {
          push @result, $item if $item->{$k} =~ $search{$k};
        }
        else {
          push @result, $item if $item->{$k} eq $search{$k};
        }
      }
    }
  }

  return wantarray ? @result : \@result;
}

1;
__END__
=encoding utf-8
=head1 NAME

Megaport::Internal::_Result - Parent class for arbitary resultsets

=head1 SYNOPSIS

    my $eq1 = $mp->session->locations->get(id => 2);
    say $eq1->name, $eq1->address->{street};

=head1 DESCRIPTION

This provides a simple but consistent interface to pull and present data from the Megaport API in a read-only manner. It fetches and caches the data on instantiation so repeated usage should be fairly responsive.

=head1 METHODS

=head2 list

    # Optional array or arrayref
    my @list = $locations->list;
    my $list = $locations->list;

    # Use search terms to find a partial list
    my @oceania = $locations->list(networkRegion => 'ANZ');
    my @uk = $locations->list(country => 'United Kingdom');

    # Or use a regexp to get a bit fancy
    my @dlr = $locations->list(name => qr/^Digital Realty/);

Returns a list or allows searching based on any field present in the object.

=head2 get

    my $gs = $locations->get(id => 3);
    my $sy3 = $locations->get(name => 'Equinix SY3');

Best used to search by C<id> but as with L<list/list>, any field can be used. This method uses L<List::Util/first> to return the first matching entry. The data is stored in a hash internally so the keys are unordered. Using this method with a search term like C<country> will yield unexpected results.


=head1 AUTHOR

Cameron Daniel E<lt>cdaniel@cpan.orgE<gt>

=cut
