package Google::RestApi::SheetsApi4::Range::Cell;

use strict;
use warnings;

our $VERSION = '0.1';

use 5.010_000;

use autodie;
use Carp qw(cluck);
use Type::Params qw(compile compile_named);
use Types::Standard qw(Str InstanceOf Any slurpy);
use YAML::Any qw(Dump);

no autovivification;

use Google::RestApi::Utils qw(named_extra);

use parent 'Google::RestApi::SheetsApi4::Range';

do 'Google/RestApi/logger_init.pl';

sub range {
  my $self = shift;
  return $self->{normalized_range} if $self->{normalized_range};
  my $range = $self->SUPER::range(@_);
  die "Unable to translate '$range' into a worksheet cell"
    if $range =~ /:/;
  return $range;
}

sub values {
  my $self = shift;
  my $p = _update_values(@_);
  my $values = $self->SUPER::values(%$p);
  return $values->[0]->[0];
}

sub batch_values {
  my $self = shift;
  my $p = _update_values(@_);
  return $self->SUPER::batch_values(%$p);
}

sub _update_values {
  state $check = compile_named(
    values  => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{values} = [[$p->{values}]] if defined $p->{values};
  return $p;
}

sub cell { shift; }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range::Cell - Perl API to Google Sheets API V4.

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
