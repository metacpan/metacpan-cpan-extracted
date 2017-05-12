package LibTracker::Client::MetaDataTypeDetails;
use strict;

use Carp;

sub new
{
	my $class = shift;
	my $args = shift or croak "no args supplied";

	croak "no type!" unless defined $args->{type};
	croak "no is_embedded!" unless defined $args->{is_embedded};
	croak "no is_writeable!" unless defined $args->{is_writeable};

	my $self = {
		type		=> $args->{type},
		is_embedded	=> $args->{is_embedded},
		is_writeable	=> $args->{is_writeable},
	};

	return bless $self, $class;
}

sub type
{
	my $self = shift;
	if(@_) {
		$self->{type} = $_[0];
	}
	return $self->{type};
}

sub is_embedded
{
	my $self = shift;
	if(@_) {
		$self->{is_embedded} = $_[0];
	}
	return $self->{is_embedded};
}

sub is_writeable
{
	my $self = shift;
	if(@_) {
		$self->{is_writeable} = $_[0];
	}
	return $self->{is_writeable};
}

1;

__END__

=head1 NAME

LibTracker::Client::MetaDataTypeDetails - Metadata type details for LT::C

=head1 SYNOPSIS

  use LibTracker::Client qw(:all);
  use LibTracker::Client::MetaDataTypeDetails;

  my $tracker = LibTracker::Client->get_instance();

  my $mdtd = $tracker->get_metadata_type_details("Doc:Author");

  print "type         : ", $mdtd->type(), "\n";
  print "is_embedded  : ", $mdtd->is_embedded(), "\n";
  print "is_writeable : ", $mdtd->is_writeable(), "\n";

  undef $tracker;

=head1 DESCRIPTION

This module implements the MetaDataTypeDetails data structure for
LibTracker::Client.

=head1 INTERFACE

=head2 STATIC METHODS

=over

=item new()

  args:
    args(hashref)    : contains the type, is_embedded and
                       is_writeable keys with values.

Returns a reference blessed into LibTracker::Client::MetaDataTypeDetails on
success. Dies on failure.

=back

=head2 INSTANCE METHODS

=over

=item type()

  args:
    type(string)[optional]     : the type

If passed an argument, sets the type field to the given value. Returns the
type for the MetaDataTypeDetails object.

=back

=over

=item is_embedded()

  args:
    is_embedded(boolean)[optional] : the is_embedded flag

If passed an argument, sets the is_embedded field to the given value.
Returns the is_embedded flag for the MetaDataTypeDetails object.

=back

=over

=item is_writeable()

  args:
    is_writeable(boolean)[optional] : the is_embedded flag

If passed an argument, sets the is_writeable field to the given value.
Returns the is_writeable flag for the MetaDataTypeDetails object.

=back

=head2 EXPORT

None by default.

=head2 Exportable constants

None.

=head1 SEE ALSO

The tracker project home at http://www.gnome.org/projects/tracker/

LibTracker::Client specific communication with the author :
ltcp@theoldmonk.net

LibTracker::Client homepage at http://www.theoldmonk.net/ltcp/

=head1 AUTHOR

Devendra Gera, E<lt>gera@theoldmonk.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Devendra Gera

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

