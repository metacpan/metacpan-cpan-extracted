package EBook::Ishmael::PDB;
use 5.016;
our $VERSION = '1.06';
use strict;
use warnings;

use EBook::Ishmael::PDB::Record;

my $HEADER_COMMON = 78;
my $RECORD_INFO = 8;

# Offset of Palm's Epoch (Jan 1, 1904) from Unix's Epoch (Jan 1, 1970)
my $EPOCH_OFFSET = -2082844800;

sub new {

	my $class = shift;
	my $pdb   = shift;

	my $self = {
		Name        => undef,
		Attr        => undef,
		Version     => undef,
		CDate       => undef,
		MDate       => undef,
		BDate       => undef,
		ModNum      => undef,
		AppInfo     => undef,
		SortInfo    => undef,
		Type        => undef,
		Creator     => undef,
		UIDSeed     => undef,
		NextRecList => undef,
		RecNum      => undef,
		Recs        => [],
		Size        => undef,
	};

	open my $fh, '<', $pdb
		or die "Failed to open $pdb for reading: $!\n";
	binmode $fh;

	seek $fh, 0, 2;
	$self->{Size} = tell $fh;
	seek $fh, 0, 0;

	read $fh, my ($hdr), $HEADER_COMMON;

	(
		$self->{Name},
		$self->{Attr},
		$self->{Version},
		$self->{CDate},
		$self->{MDate},
		$self->{BDate},
		$self->{ModNum},
		$self->{AppInfo},
		$self->{SortInfo},
		$self->{Type},
		$self->{Creator},
		$self->{UIDSeed},
		$self->{NextRecList},
		$self->{RecNum},
	) = unpack "a32 n n N N N N N N N N N N n", $hdr;

	unless ($self->{Name} =~ /\0$/) {
		die "$self->{Source} is not a PDB file, name is not null-terminated\n";
	}

	unless ($self->{NextRecList} == 0) {
		die "$pdb is not a PDB file\n";
	}

	if ($self->{RecNum} == 0) {
		die "PDB $pdb has no records\n";
	}

	# If the epoch offset knocks the time below zero, then that probably means
	# that the time was stored as a Unix time.
	$self->{CDate} &&= $self->{CDate} + $EPOCH_OFFSET > 0
		? $self->{CDate} + $EPOCH_OFFSET
		: $self->{CDate};
	$self->{MDate} &&= $self->{MDate} + $EPOCH_OFFSET > 0
		? $self->{MDate} + $EPOCH_OFFSET
		: $self->{MDate};
	$self->{BDate} &&= $self->{BDate} + $EPOCH_OFFSET > 0
		? $self->{BDate} + $EPOCH_OFFSET
		: $self->{BDate};

	my @recs;

	for my $i (0 .. $self->{RecNum} - 1) {

		read $fh, my ($buf), $RECORD_INFO;

		my $rec = {};

		(
			$rec->{Offset},
			$rec->{Attributes},
			$rec->{UID},
		) = unpack "N C C3", $buf;

		if ($rec->{Offset} > $self->{Size}) {
			die "Malformed PDB file: $pdb\n";
		}

		push @recs, $rec;

	}

	for my $i (0 .. $self->{RecNum} - 1) {

		my $size = $i == $self->{RecNum} - 1
			? $self->{Size}           - $recs[$i]->{Offset}
			: $recs[$i + 1]->{Offset} - $recs[$i]->{Offset};

		seek $fh, $recs[$i]->{Offset}, 0;

		read $fh, my ($buf), $size;

		push @{ $self->{Recs} }, EBook::Ishmael::PDB::Record->new(
			$buf,
			$recs[$i]
		);

	}

	return bless $self, $class;

}

sub name {

	my $self = shift;

	return $self->{Name} =~ s/\0+$//r;

}

sub attributes {

	my $self = shift;

	return $self->{Attr};

}

sub version {

	my $self = shift;

	return $self->{Version};

}

sub cdate {

	my $self = shift;

	return $self->{CDate};

}

sub mdate {

	my $self = shift;

	return $self->{MDate};

}

sub bdate {

	my $self = shift;

	return $self->{BDate};

}

sub modnum {

	my $self = shift;

	return $self->{ModNum};

}

sub app_info {

	my $self = shift;

	return $self->{AppInfo};

}

sub sort_info {

	my $self = shift;

	return $self->{SortInfo};

}

sub type {

	my $self = shift;

	return $self->{Type};

}

sub creator {

	my $self = shift;

	return $self->{Creator};

}

sub uid_seed {

	my $self = shift;

	return $self->{UIDSeed};

}

sub next_rec_list {

	my $self = shift;

	return $self->{NextRecList};

}

sub recnum {

	my $self = shift;

	return $self->{RecNum};

}

sub record {

	my $self = shift;
	my $rec  = shift;

	return $self->{Recs}->[$rec];

}

sub records {

	my $self = shift;

	return @{ $self->{Recs} };

}

sub size {

	my $self = shift;

	return $self->{Size};

}

1;

=head1 NAME

EBook::Ishmael::PDB - ishmael PDB interface

=head1 SYNOPSIS

  use EBook::Ishmael::PDB;

  my $pdb = EBook::Ishmael::PDB->new($file);

=head1 DESCRIPTION

B<EBook::Ishmael::PDB> is a simple interface for reading Palm PDB files.
For L<ishmael> user documentation, you should consult its manual (this is
developer documentation).

=head1 METHODS

=head2 $p = EBook::Ishmael::PDB->new($pdb)

Returns a blessed C<EBook::Ishmael::PDB> object representing the given
PDB file C<$pdb>.

=head2 $n = $p->name()

Returns the PDB's name (with the null characters stripped out).

=head2 $a = $p->attributes()

Returns the PDB's attribute bitfield.

=head2 $v = $p->version()

Returns the PDB's version.

=head2 $c = $p->cdate()

Returns the PDB's creation date.

=head2 $m = $p->mdate()

Returns the PDB's modification date.

=head2 $b = $p->bdate()

Returns the PDB's backup date.

=head2 $m = $p->modnum()

Returns the PDB's modification number.

=head2 $a = $p->app_info()

Returns the PDB's app info area offset.

=head2 $s = $p->sort_info()

Returns the PDB's sort info area offset.

=head2 $t = $p->type()

Returns the PDB's type.

=head2 $c = $p->creator()

Returns the PDB's creator.

=head2 $u = $p->uid_seed()

Returns the PDB's UID seed.

=head2 $n = $p->next_rec_list()

Returns the PDB's next record list (should always be C<0>).

=head2 $r = $p->recnum()

Returns the PDB's record count.

=head2 $r = $p->record($rec)

Returns the C<$r>th record object in the PDB object.

=head2 @r = $p->records()

Returns array of record objects in the PDB object.

=head2 $s = $p->size()

Returns the PDB's size.

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

L<EBook::Ishmael::PDB::Record>

=cut
