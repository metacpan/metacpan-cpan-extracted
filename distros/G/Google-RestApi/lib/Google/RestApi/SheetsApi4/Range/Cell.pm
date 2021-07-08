package Google::RestApi::SheetsApi4::Range::Cell;

our $VERSION = '0.7';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SheetsApi4::Range';

# make sure the translated range refers to a single cell (no ':').
sub range {
  my $self = shift;
  return $self->{normalized_range} if $self->{normalized_range};
  my $range = $self->SUPER::range(@_);
  LOGDIE "Unable to translate '$range' into a worksheet cell"
    if $range =~ /:/;
  return $range;
}

sub values {
  my $self = shift;
  state $check = compile_named(
    values => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{values} = [[ $p->{values} ]] if defined $p->{values};
  my $values = $self->SUPER::values(%$p);
  return defined $values ? $values->[0]->[0] : undef;
}

sub batch_values {
  my $self = shift;

  state $check = compile_named(
    values => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  $p->{values} = [[ $p->{values} ]] if $p->{values};
  return $self->SUPER::batch_values(%$p);
}

sub cell { shift; }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range::Cell - Represents a cell within a Worksheet.

=head1 DESCRIPTION

A Range::Cell object modifies the behaviour of the parent Range object
to treat the values used within the range as a plain string instead of
arrays of arrays. This object will encapsulate the passed string value
into a [[$value]] array of arrays when interacting with Goolge API.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
