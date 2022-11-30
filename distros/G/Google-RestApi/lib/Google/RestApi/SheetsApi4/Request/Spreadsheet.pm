package Google::RestApi::SheetsApi4::Request::Spreadsheet;

our $VERSION = '1.0.4';

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

Copyright (c) 2021, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
