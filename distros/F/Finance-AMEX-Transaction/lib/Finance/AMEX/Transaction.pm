package Finance::AMEX::Transaction 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX transaction files: EPRAW, EPPRC, EPTRN, CBNOT, GRRCN

use Finance::AMEX::Transaction::CBNOT;
use Finance::AMEX::Transaction::EPRAW;
use Finance::AMEX::Transaction::EPPRC;
use Finance::AMEX::Transaction::EPTRN;
use Finance::AMEX::Transaction::GRRCN;

sub new {
  my ($class, %props) = @_;

  my $self = bless {
    _file_type    => undef,
    _file_format  => undef,
    _file_version => undef,
    _parser       => undef,
  }, $class;

  my $type_map = {
    EPRAW => 'Finance::AMEX::Transaction::EPRAW',
    EPPRC => 'Finance::AMEX::Transaction::EPPRC',
    EPTRN => 'Finance::AMEX::Transaction::EPTRN',
    CBNOT => 'Finance::AMEX::Transaction::CBNOT',
    GRRCN => 'Finance::AMEX::Transaction::GRRCN',
  };

  $self->{_file_type}    = $props{file_type};
  $self->{_file_format}  = $props{file_format}  || 'UNKNOWN';
  $self->{_file_version} = $props{file_version} || 'UNKNOWN';

  if ($self->file_type and exists $type_map->{$self->file_type}) {
    $self->{_parser} = $type_map->{$self->file_type}->new(
      file_format  => $self->file_format,
      file_version => $self->file_version,
    );
  }

  return $self;
}

sub file_type {
  my ($self) = @_;

  return $self->{_file_type};
}

sub file_format {
  my ($self) = @_;

  return $self->{_file_format};
}

sub file_version {
  my ($self) = @_;

  return $self->{_file_version};
}

sub parser {
  my ($self) = @_;

  return $self->{_parser};
}

sub getline {
  my ($self, $fh) = @_;

  my $line = <$fh>;
  return $self->parse_line($line);
}

sub parse_line {
  my ($self, $line) = @_;

  my $ret = $self->{_parser}->parse_line($line);

  $self->_set_file_format;
  $self->_set_file_version;

  return $ret;
}

sub _set_file_format {
  my ($self) = @_;

  return if not $self->file_format eq 'UNKNOWN';
  return if $self->file_format eq $self->{_parser}->file_format;
  return if $self->{_parser}->file_format eq 'UNKNOWN';

  $self->{_file_format} = $self->{_parser}->file_format;

  return $self->file_format;
}

sub _set_file_version {
  my ($self) = @_;

  return if not $self->file_version eq 'UNKNOWN';
  return if $self->file_version eq $self->{_parser}->file_version;
  return if $self->{_parser}->file_version eq 'UNKNOWN';

  $self->{_file_version} = $self->{_parser}->file_version;

  return $self->file_version;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction - Parse AMEX transaction files: EPRAW, EPPRC, EPTRN, CBNOT, GRRCN

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Finance::AMEX::Transaction;

  my $cbnot = Finance::AMEX::Transaction->new(file_type => 'CBNOT');
  open my $fh, '<', '/path to CBNOT file' or die "cannot open CBNOT file: $!";

  while (my $record = $cbnot->getline($fh)) {

    if ($record->type eq 'TRAILER') {
      print $record->FILE_CREATION_DATE . "\n";
    }
  }

=head1 DESCRIPTION

This module parses AMEX transaction files and returns object that are appropriate for the line that it was asked to parse.

=head1 METHODS

=head2 new

Creates a new L<Finance::AMEX::Transaction> object.  Required options are C<file_type>).

 my $cbnot = Finance::AMEX::Transaction->new(file_type => 'CBNOT');

=over 4

=item C<file_type> (required)

Sets the type of file that we are parsing.  Valid values are:

=over 4

=item EPRAW

returns L<Finance::AMEX::Transaction::EPRAW> objects.

=item EPPRC

returns L<Finance::AMEX::Transaction::EPPRC> objects.

=item EPTRN

returns L<Finance::AMEX::Transaction::EPTRN> objects.

=item CBNOT

returns L<Finance::AMEX::Transaction::CBNOT> objects.

=item GRRCN

returns L<Finance::AMEX::Transaction::GRRCN> objects.

=back

=item C<file_format>

Sets the format of the file that we are parsing.  Currently only useful for L<Finance::AMEX::Transaction::GRRCN> files.  This should be auto-detected after the first row is parsed.

Should be one of FIXED, CSV, TSV.

=over 4

=item fixed

The file is in a fixed width format.

=item csv

The file has comma separated values.

=item tsv

The file has tab separated values.

=back

=item C<file_version>

Sets the version of the file we are parsing.  Currently only useful for L<Finance::AMEX::Transaction::GRRCN> files.  This should be auto-detected after the HEADER row is parsed.

Should be one of 1.01, 2.01, 3.01.

=back

=head2 file_type

Access method for the file type you set when calling C<new>

=head2 file_format

Access method for the file formatted type that was set when calling C<new> or was auto-detected after the first row is parsed.

=head2 file_version

Access method for the file version that was set when calling C<new> or was auto-detected after the HEADER row is parsed.

=head2 parser

Access method for the parser that is set depending on C<file_type>

=head2 getline

When passed a filehandle, takes the next line from the file and returns the appropriate object.

 my $record = $cbnot->getline($fh);

=head2 parse_line

Parses a single line from a file and returns the appropriate object.

=head1 NAME

Finance::AMEX::Transaction - Parse AMEX transaction files: EPRAW, EPPRC, EPA, CBNOT, GRRCN

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
