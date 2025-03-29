package EBook::Ishmael::PDB::Record;
use 5.016;
our $VERSION = '1.04';
use strict;
use warnings;

sub new {

	my $class  = shift;
	my $data   = shift;
	my $params = shift;

	my $self = {
		Data => $data,
		Off  => $params->{Offset},
		Attr => $params->{Attributes},
		UID  => $params->{UID},
	};

	return bless $self, $class;

}

sub data {

	my $self = shift;

	return $self->{Data};

}

sub offset {

	my $self = shift;

	return $self->{Off};

}

sub attributes {

	my $self = shift;

	return $self->{Attr};

}

sub uid {

	my $self = shift;

	return $self->{UID};

}

1;

=head1 NAME

EBook::Ishmael::PDB::Record - ishmael PDB record interface

=head1 SYNOPSIS

  use EBook::Ishmael::PDB::Record;

  my $rec = EBook::Ishmael::PDB::Record->new(
      $data,
      {
          Offset => $offset,
          Attributes => $attr,
          UID => $uid
      }
  );

=head1 DESCRIPTION

B<EBook::Ishmael::PDB::Record> is a module that provides an interface
for reading Palm PDB records. For L<ishmael> user documentation, you should
consult its manual (this is developer documentation).

=head1 METHODS

=head2 $r = EBook::Ishmael::PDB::Record->new($data, $info)

Returns a blessed B<EBook::Ishmael::PDB::Record> object. C<$data> is a
scalar holding the record's data, C<$info> is a hash ref of the record's info
data.

=over 4

=item Off

The record's offset.

=item Attributes

The record's attribute bitfield.

=item UID

The record's UID.

=back

=head2 $d = $r->data()

Returns the record's data.

=head2 $o = $r->offset()

Returns the record's offset.

=head2 $a = $r->attributes()

Returns the record's attribute bitfield.

=head2 $u = $r->uid()

Returns the record's UID.

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<EBook::Ishmael::PDB>

=cut
