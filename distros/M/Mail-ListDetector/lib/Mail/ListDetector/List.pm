package Mail::ListDetector::List;

use strict;
use warnings;

sub new {
  my $proto = shift;
  my $data = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  $self->{'data'} = $data;

  bless ($self, $class);
  return $self;
}

sub listname {
  my $self = shift;
  my $name = shift;
  $self->{'data'}->{'listname'} = $name if defined $name;
  return $self->{'data'}->{'listname'};
}

sub posting_address {
  my $self = shift;
  my $posting_address = shift;
  $self->{'data'}->{'posting_address'} = $posting_address if defined $posting_address;
  return $self->{'data'}->{'posting_address'};
}

sub listsoftware {
  my $self = shift;
  my $listsoftware = shift;
  $self->{'data'}->{'listsoftware'} = $listsoftware if defined $listsoftware;
  return $self->{'data'}->{'listsoftware'};
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::List - an object representing a mailing list

=head1 SYNOPSIS

  use Mail::ListDetector::List;

=head1 DESCRIPTION

This object provides a representation of the information extracted
about a mailing list. It should not be instantiated directly by anything
outside the Mail::ListDetector package.

=head1 METHODS

=head2 new

Creates a new List object.

=head2 listname

This method gets or sets the name of the mailing list. The name to
set is an optional argument.

=head2 posting_address

This method gets or sets the posting address of the mailing list.
The posting address to set is an optional argument.

=head2 listsoftware

This method gets or sets the mailing list software name. The name
to set is an optional argument.

=head1 BUGS

No known bugs.

=head1 AUTHOR

Michael Stevens - michael@etla.org.

=cut

