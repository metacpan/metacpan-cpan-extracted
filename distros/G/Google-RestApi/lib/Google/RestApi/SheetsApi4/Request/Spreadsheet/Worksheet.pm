package Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet;

our $VERSION = '0.8';

use Google::RestApi::Setup;

use aliased "Google::RestApi::SheetsApi4::Request";
use parent "Google::RestApi::SheetsApi4::Request::Spreadsheet";

sub worksheet_id { LOGDIE "Pure virtual function 'worksheet_id' must be overridden"; }

sub ws_rename { shift->update_worksheet_properties(properties => { title => shift }); }
sub ws_index { shift->update_worksheet_properties(properties => { index => shift }); }
sub ws_hide { shift->update_worksheet_properties(properties => { hidden => bool(shift) }); }
sub ws_hidden { ws_hide(@_); }
sub ws_right_to_left { shift->update_worksheet_properties(properties => { rightToLeft => bool(shift) }); }
sub ws_left_to_right { shift->ws_right_to_left(bool(shift) eq 'true' ? 0 : 1); }

sub _ws_tab_rgba { shift->ws_tab_color({ (shift) => (shift // 1) }); }
sub ws_tab_red { shift->_ws_tab_rgba('red' => shift); }
sub ws_tab_blue { shift->_ws_tab_rgba('blue' => shift); }
sub ws_tab_green { shift->_ws_tab_rgba('green' => shift); }
sub ws_tab_alpha { shift->_ws_tab_rgba('alpha' => shift); }
sub ws_tab_black { shift->ws_tab_color(cl_black()); }
sub ws_tab_white { shift->ws_tab_color(cl_white()); }
sub ws_tab_color { shift->update_worksheet_properties(properties => { tabColor => shift }); }

sub freeze_cols { shift->_freeze('col', @_); }
sub freeze_rows { shift->_freeze('row', @_); }
sub unfreeze_cols { shift->freeze_cols(); }
sub unfreeze_rows { shift->freeze_rows(); }
sub _freeze {
  my $self = shift;

  my $dim = shift;
  state $check = compile(PositiveOrZeroInt, { default => 0 });
  my ($count) = $check->(@_);

  # "frozenColumnCount" or "frozenRowCount".
  my $frozen = "frozen" . ($dim eq 'col' ? "Column" : "Row") . "Count";

  return $self->update_worksheet_properties(
    properties => { gridProperties => { $frozen => $count }, },
    fields     => "gridProperties.$frozen",
  );
}

sub update_worksheet_properties {
  my $self = shift;

  state $check = compile_named(
    properties => HashRef,
    fields     => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  my $properties = $p->{properties};
  my $fields = $p->{fields} || join(',', sort keys %$properties);

  $self->batch_requests(
    updateSheetProperties => {
      properties => {
        sheetId => $self->worksheet_id(),
        %$properties,
      },
      fields     => $fields,
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

sub reset { shift->clear_formatting()->clear_values()->unfreeze_cols()->unfreeze_rows(); }

sub delete_worksheet {
  my $self = shift;
  $self->batch_requests(
    deleteSheet => { sheetId => $self->worksheet_id() }
  );
  return $self;
}

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet - Build Google API's batchRequests for a Worksheet.

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
