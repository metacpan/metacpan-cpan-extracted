package File::Open::OOP;
use strict;
use warnings;

our $VERSION = '0.01';

use base 'Exporter';
use File::Open qw(fopen);

our @EXPORT_OK = qw(oopen);

=head1 NAME

File::Open::OOP - An Object Oriented way to read and write files

=head1 SYNOPSIS

Reading lines one-by-one 

  use File::Open::OOP qw(oopen);

  my $fh = oopen 'filename';
  while ( my $row = $fh->readline ) {
  	print $row;
  }

Reading all the line at once:

  my @rows = oopen('filename')->readall;

Reading all the lines into a single scalar:

  my $rows = oopen('filename')->slurp;

=head1 OTHER

This module is based on the L<File::Open> module of Lukas Mai.

=head1 AUTHOR

Gabor Szabo C<< <gabor@szabgab.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Gabor Szabo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

sub new {
	my ($class, %args) = @_;
	my $self = \%args;

	return bless $self, $class;
}

sub oopen {
	my $fh = fopen(@_);
	return File::Open::OOP->new(fh => $fh);
}

sub readline {
	my ($self) = @_;
	my $fh = $self->{fh};
	return scalar <$fh>;
}

sub readall {
	my ($self) = @_;
	my $fh = $self->{fh};
	return <$fh>;
}

sub slurp {
	my ($self) = @_;
	my $fh = $self->{fh};
	local $/ = undef;
	return scalar <$fh>;
}

1;
