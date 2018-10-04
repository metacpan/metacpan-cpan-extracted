package Finance::AMEX::Transaction::CBNOT;
$Finance::AMEX::Transaction::CBNOT::VERSION = '0.003';
use strict;
use warnings;

use Finance::AMEX::Transaction::CBNOT::Header;
use Finance::AMEX::Transaction::CBNOT::Detail;
use Finance::AMEX::Transaction::CBNOT::Trailer;
use Finance::AMEX::Transaction::CBNOT::Unknown;

# ABSTRACT: Parse AMEX Chargeback Notification Files (CBNOT)

sub new {
  my ($class, %props) = @_;

  my $type_map = {
    H => 'Finance::AMEX::Transaction::CBNOT::Header',
    D => 'Finance::AMEX::Transaction::CBNOT::Detail',
    T => 'Finance::AMEX::Transaction::CBNOT::Trailer',
  };

  my $self = bless {
    _type_map => $type_map,
  }, $class;

  return $self;
}

sub parse_line {
  my ($self, $line) = @_;

  return if not defined $line;

  my $indicator = substr($line, 0, 1);
  if (exists $self->{_type_map}->{$indicator}) {
    return $self->{_type_map}->{$indicator}->new(line => $line);
  }
  return Finance::AMEX::Transaction::CBNOT::Unknown->new(line => $line);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::CBNOT - Parse AMEX Chargeback Notification Files (CBNOT)

=head1 VERSION

version 0.003

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

This module parses AMEX Chargeback Notification Files (CBNOT) and returns an object which is appropriate for the line that it was asked to parse.

You would not normally be calling this module directly, it is merely a router to the correct object type that is returned to L<Finance::AMEX::Transaction>'s getline method.

Object returned are one of:

=over 4

=item L<Finance::AMEX::Transaction::CBNOT::Header>

Header Rows

 print $record->type; # HEADER

=item L<Finance::AMEX::Transaction::CBNOT::Detail>

Detail Rows

 print $record->type; # DETAIL

=item L<Finance::AMEX::Transaction::CBNOT::Trailer>

Trailer Rows

 print $record->type; # TRAILER

=item L<Finance::AMEX::Transaction::CBNOT::Unknown>

Unknown lines.

 print $record->type; # UNKNOWN

=back

=head1 METHODS

=head2 new

Returns a L<Finance::AMEX::Transaction::CBNOT> object.

 my $cbnot = Finance::AMEX::Transaction::CBNOT->new;

=head2 parse_line

Returns one of the L<Finance::AMEX::Transaction::CBNOT::Header>, L<Finance::AMEX::Transaction::CBNOT::Detail>, L<Finance::AMEX::Transaction::CBNOT::Trailer>, or L<Finance::AMEX::Transaction::CBNOT::Unknown> records depending on the contents of the line.

 my $record = $cbnot->parse_line('line from a cbnot file');

=head1 NAME

Finance::AMEX::Transaction::CBNOT - Parse AMEX Chargeback Notification Files (CBNOT)

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
