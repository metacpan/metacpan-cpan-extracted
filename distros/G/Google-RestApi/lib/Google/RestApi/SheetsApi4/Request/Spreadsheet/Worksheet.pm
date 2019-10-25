package Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet;

use strict;
use warnings;

our $VERSION = '0.1';

use 5.010_000;

use autodie;
use Type::Params qw(compile compile_named);
use Types::Standard qw(Int HasMethods);
use YAML::Any qw(Dump);

no autovivification;

use parent "Google::RestApi::SheetsApi4::Request::Spreadsheet";

do 'Google/RestApi/logger_init.pl';

sub worksheet_id { die "Pure virtual function 'worksheet_id' must be overridden"; }

sub freeze_cols { shift->_freeze('col', @_); }
sub freeze_rows { shift->_freeze('row', @_); }
sub _freeze {
  my $self = shift;

  my $dim = shift;
  state $check = compile(Int->where('$_ > -1'), { default => 0 });
  my ($count) = $check->(@_);

  my $frozen = "frozen" . ($dim eq 'col' ? "Column" : "Row") . "Count";   # frozenColumnCount or frozenRowCount.

  $self->batch_requests(
    updateSheetProperties => {
      properties => {
        sheetId        => $self->worksheet_id(),
        gridProperties => { $frozen => $count },
      },
      fields     => "gridProperties.$frozen",
    },
  );

  return $self;
}

sub clear_values { shift->_clear("userEnteredValue"); }
sub clear_formatting { shift->_clear("userEnteredFormat"); }
sub _clear {
  my $self = shift;
  my $fields = shift;
  my $range = shift || { sheetId => $self->worksheet_id() };
  $self->batch_requests(
    updateCells => {
      range  => $range,
      fields => $fields,
    },
  );
  return $self;
}

sub reset { shift->clear_formatting()->clear_values()->freeze_rows()->freeze_cols(); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet - Perl API to Google Sheets API V4.

=head1 DESCRIPTION

Deriving from the Request::Spreadsheet object, this adds the ability to create
requests that have to do with worksheet properties.

See the description and synopsis at Google::RestApi::SheetsApi4::Request.
and Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
