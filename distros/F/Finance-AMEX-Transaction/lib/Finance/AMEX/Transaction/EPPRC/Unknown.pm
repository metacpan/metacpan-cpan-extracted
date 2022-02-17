package Finance::AMEX::Transaction::EPPRC::Unknown 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Unknown Rows

sub new {
  my ($class, %props) = @_;
  my $self = bless {_line => $props{line}}, $class;
  return $self;
}

sub type {return 'UNKNOWN'}

sub line {
  my ($self) = @_;
  return $self->{_line};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPPRC::Unknown - Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Unknown Rows

=head1 VERSION

version 0.005

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

You should only be getting this type of object if it is an unknown or invalid EPPRC file or line.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::EPPRC::Unknown> object.

 my $record = Finance::AMEX::Transaction::EPPRC::Unknown->new(line => $line);

=head2 type

This will always return the string UNKNOWN.

 print $record->type; # UNKNOWN

=head2 line

Returns the full line that was given to the object.

=head1 NAME

Finance::AMEX::Transaction::EPPRC::Unknown - Object methods for unknown AMEX reconciliation file records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
