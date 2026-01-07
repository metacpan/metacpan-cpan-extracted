package Google::RestApi::SheetsApi4::Request::Spreadsheet;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

use parent "Google::RestApi::SheetsApi4::Request";

sub spreadsheet_id { LOGDIE "Pure virtual function 'spreadsheet_id' must be overridden"; }

sub delete_protected_range {
  my $self = shift;

  state $check = compile(Str);
  my ($id) = $check->(@_);

  $self->batch_requests(
    deleteProtectedRange => {
      protectedRangeId => $id,
    },
  );

  return $self;
}

sub add_worksheet {
  my $self = shift;

  state $check = compile_named(
    name            => Optional[Str],
    title           => Optional[Str],
    grid_properties => Optional[Dict[ rows => Optional[Int], cols => Optional[Int] ]],
    tab_color       => Optional[Dict[ red => Optional[Num], blue => Optional[Num], green => Optional[Num] ]],
  );
  my $p = $check->(@_);

  my %properties;
  $properties{title} = $p->{title} if $p->{title};
  $properties{title} = $p->{name} if $p->{name};
  $properties{tabColor} = $p->{tab_color} if $p->{tab_color};

  $p->{grid_properties}->{rowCount} = delete $p->{grid_properties}->{rows} if $p->{grid_properties}->{rows};
  $p->{grid_properties}->{columnCount} = delete $p->{grid_properties}->{cols} if $p->{grid_properties}->{cols};
  $properties{gridProperties} = $p->{grid_properties} if $p->{grid_properties};

  $self->batch_requests(addSheet => { properties => \%properties });

  return $self;
}

sub update_spreadsheet_properties {
  my $self = shift;

  state $check = compile_named(
    properties => HashRef,
    fields     => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  my $properties = $p->{properties};
  my $fields = $p->{fields} || join(',', sort keys %$properties);

  $self->batch_requests(
    updateSpreadsheetProperties => {
      properties => $properties,
      fields     => $fields,
    },
  );

  return $self;
}

sub ss_title { shift->update_spreadsheet_properties(properties => { title => shift }); }
sub ss_locale { shift->update_spreadsheet_properties(properties => { locale => shift }); }
sub ss_time_zone { shift->update_spreadsheet_properties(properties => { timeZone => shift }); }
sub ss_auto_recalc { shift->update_spreadsheet_properties(properties => { autoRecalc => shift }); }
sub ss_iteration_count {
  my $self = shift;
  $self->update_spreadsheet_properties(
    properties => { iterativeCalculationSettings => { maxIterations => shift } },
    fields     => 'iterativeCalculationSettings.maxIterations',
  );
}
sub ss_iteration_threshold {
  my $self = shift;
  $self->update_spreadsheet_properties(
    properties => { iterativeCalculationSettings => { convergenceThreshold => shift } },
    fields     => 'iterativeCalculationSettings.convergenceThreshold',
  );
}
sub ss_default_format {
  my $self = shift;
  $self->update_spreadsheet_properties(
    properties => { defaultFormat => shift },
    fields     => 'defaultFormat',
  );
}

sub add_protected_range {
  my $self = shift;

  state $check = compile_named(
    range            => HashRef,
    description      => Optional[Str],
    warning_only     => Optional[Bool],
    requesting_user  => Optional[Bool],
    editors          => Optional[HashRef],
  );
  my $p = $check->(@_);

  my %protected_range = (range => $p->{range});
  $protected_range{description} = $p->{description} if defined $p->{description};
  $protected_range{warningOnly} = bool($p->{warning_only}) if defined $p->{warning_only};
  $protected_range{requestingUserCanEdit} = bool($p->{requesting_user}) if defined $p->{requesting_user};
  $protected_range{editors} = $p->{editors} if $p->{editors};

  $self->batch_requests(
    addProtectedRange => {
      protectedRange => \%protected_range,
    },
  );

  return $self;
}

sub update_protected_range {
  my $self = shift;

  state $check = compile_named(
    id               => Str,
    range            => Optional[HashRef],
    description      => Optional[Str],
    warning_only     => Optional[Bool],
    requesting_user  => Optional[Bool],
    editors          => Optional[HashRef],
    fields           => Optional[Str],
  );
  my $p = $check->(@_);

  my %protected_range = (protectedRangeId => $p->{id});
  $protected_range{range} = $p->{range} if $p->{range};
  $protected_range{description} = $p->{description} if defined $p->{description};
  $protected_range{warningOnly} = bool($p->{warning_only}) if defined $p->{warning_only};
  $protected_range{requestingUserCanEdit} = bool($p->{requesting_user}) if defined $p->{requesting_user};
  $protected_range{editors} = $p->{editors} if $p->{editors};

  my @field_list;
  push @field_list, 'range' if $p->{range};
  push @field_list, 'description' if defined $p->{description};
  push @field_list, 'warningOnly' if defined $p->{warning_only};
  push @field_list, 'requestingUserCanEdit' if defined $p->{requesting_user};
  push @field_list, 'editors' if $p->{editors};
  my $fields = $p->{fields} || join(',', @field_list);

  $self->batch_requests(
    updateProtectedRange => {
      protectedRange => \%protected_range,
      fields         => $fields,
    },
  );

  return $self;
}

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Request::Spreadsheet - Build Google API's batchRequests for a Spreadsheet.

=head1 DESCRIPTION

Deriving from the Request object, this adds the ability to create
requests that have to do with spreadsheet properties.

See the description and synopsis at Google::RestApi::SheetsApi4::Request.
and Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
