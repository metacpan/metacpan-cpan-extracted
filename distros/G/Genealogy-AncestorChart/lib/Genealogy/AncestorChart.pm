=head1 NAME

Genealogy::AncestorChart - create a table of genealogical ancestors.

=head1 SYNOPSIS

    use Genealogy::AncestorChart;

    my @people = ($me, $dad, $mum, ...);

    my $chart = Genealogy::AncestorChart->new({
      people => \@people,
    });

    say $gac->chart;

=head1 DESCRIPTION

This module draws an HTML table which contains a representation of ancestors.
For the first three generations, the table will look like this:

  +-------------+-------------+----------------+
  | Person      | Parents     | Grandparents   |
  +-------------+-------------+----------------+
  | 1: Person   | 2: Father   | 4: Grandfather |
  |             |             +----------------+
  |             |             | 5: Grandmother |
  |             +-------------+----------------+ 
  |             | 3: Mother   | 6: Grandfather |
  |             |             +----------------+
  |             |             | 7: Grandmother |
  +-------------+-------------+----------------+ 

The labels inside the table are generated from the array of people that is
passed into the constructor when the object is created.

=head1 METHODS

=head2 new(\%options)

The constructor method. Builds a new instance of the class and returns that
object. Takes a hash reference containing various parameters.

=over 4

=item * people

This is the only mandatory option.

This should be a reference to a hash of objects. The key in the hash should
be an "Ahnentafel number" (see below) and the value should be an object will
represent one person to be displayed in the output. The text displayed
for each person is retrieved by calling a method on the relevant object.
The default method name is C<display_name>, but this can be changed
using the C<label_method> option, described below.

These objects can be of any class - as long as they have a method of the
correct name that returns a text string that can be used in the table
output to identify the person in question.

The keys in the hash should be "Ahnentafel numbers". This is a series
of positive integers that genealogists use to identify the ancestors of
an individual. The person of interest is given the number 1. Their
father and mother are 2 and 3, respectively. Their grandparents are
numbers 4 to 7 in the order father's father, father's mother, mother's
father and mother's mother. These numbers have the property that if you
know the number of a person in the hash, then you can get the number of
their father by doubling their number. Similarly, you can get the number
of their mother by doubling their number and adding one.

Because of the nature of the table that is produced, the number of
people in your array should be one less than a power of two (i.e. 1, 3,
7, 15, 31, 63, etc.) For any any other number, a table will still be
produced, but it won't be guaranteed to be valid HTML.

In the future, I might introduce a "strict" mode that only allows a valid
number of people in the array.

=item * label_method

This is the name of the method that should be called on the objects in the
"people" array. The default value is C<display_name>.

=item * headers

An array reference containing the list of titles that are used for the first
few columns in the table. The default list is 'Person', 'Parents',
'Grandparents' and 'Great Grandparents'. You might want to override this if,
for example, you want the output in a different language.

=item * extra_headers

A string containing the basis for an extra headers that are required after
the fixed list stored in C<headers>. In English, we use the terms
'Great Great Grandparents', 'Great Great Great Grandparents' and so on. So
the default value for this string is 'Gt Grandparents'. This is prepended
with an incrementing string (which starts at 2) so we get the strings
'2 Gt Grandparents', '3 Gt Grandparents', and so on.

You might want to override this if, for example, you want the output in a
different language.

=back

=cut

package Genealogy::AncestorChart;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Moo;
use Types::Standard qw[ArrayRef HashRef Str Object];

has people => (
  is => 'ro',
  isa => HashRef[Object],
  required => 1,
);

=head2 num_people

Returns the number of people in the list of people.

=cut

sub num_people {
  return keys %{ $_[0]->people };
}

has label_method => (
  is => 'lazy',
  isa => Str,
);

sub _build_label_method {
  return 'display_name',
}

has headers => (
  is => 'lazy',
  isa => ArrayRef[Str],
);

sub _build_headers {
  return [
    'Person', 'Parents', 'Grandparents',
    'Great Grandparents',
  ];
}

has extra_header => (
  is => 'lazy',
  isa => Str,
);

sub _build_extra_header {
  return 'Gt Grandparents';
}

=head2 num_rows

Returns the number of rows that will be in the table. This is calculated
from the list of people.

It is unlikely that you will need to call this method.

=cut

sub num_rows {
  my $self = shift;

  return int ( keys( %{ $self->people } ) / 2 ) + 1;
}

=head2 rows

Returns the list of rows that will be used to create the table.

It is unlikely that you will need to call this method.

=cut

sub rows {
  my $self = shift;

  my ($start, $end) = $self->row_range;

  return map { $self->row($_) } $start .. $end;
}

=head2 row_range

Returns a start and end point that is used in creating the rows of
the table.

It is unlikely that you will need to call this method.

=cut

sub row_range {
  my $self = shift;

  my $end = keys %{ $self->people };
  my $start = int(($end / 2) + 1);

  return ($start, $end);
}

=head2 num_cols

Returns the number of columns that will be in the table. This is calculated
from the list of people.

It is unlikely that you will need to call this method.

=cut
sub num_cols {
  my $self = shift;

  return int log( $self->num_people ) / log(2) + 1;
}

=head2 row

Returns the HTML that makes up one row in the table.

It is unlikely that you will need to call this method.

=cut

sub row {
  my $self = shift;
  my ($rownum) = @_;

  my @cells;
  my $rowspan = 1;
  my $i       = $rownum;

  my $label_method = $self->label_method;

  while (1) {
    my $person = exists $self->people->{$i} ? $self->people->{$i} : undef;
    my $class  = $person ? $person->known ? 'success' : 'danger' : 'danger';
    my $desc   = "$i: " . ($person ? $person->$label_method : '');
    my $td     = qq[<td rowspan="$rowspan" class="$class">$desc</td>\n];
    unshift @cells, $td;

    last if $i % 2;
    $rowspan *= 2;
    $i       /= 2;
  }

  return join '', "<tr>\n", @cells, "</tr>\n";
}

=head2 table_headers

Calculates and returns the headers used in the table.

=cut

sub table_headers {
  my $self = shift;

  my @headers;
  if ($self->num_cols <= @{ $self->headers }) {
    @headers = @{ $self->headers }[0 .. $self->num_cols - 1];
  } else {
    @headers = @{ $self->headers };
    my $gt = 2;
    for (@headers .. $self->num_cols - 1) {
      push @headers, $gt++ . ' ' . $self->extra_header;
    }
  }

  return \@headers;
}

=head2 chart

Returns the complete HTML of the ancestor chart.

=cut

sub chart {
  my $self = shift;

  my $headers = join "\n", map { "<th>$_</th>"} @{ $self->table_headers };

  my $table = <<EOTABLE;
<table class="main table table-bordered table-condensed">
  <thead>
    <tr>
      $headers
    </tr>
  </thead>
  <tbody>
EOTABLE

  $table .= join '', $self->rows;

  $table .= "\n</tbody>\n</table>";

  return $table;
}

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2022, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
