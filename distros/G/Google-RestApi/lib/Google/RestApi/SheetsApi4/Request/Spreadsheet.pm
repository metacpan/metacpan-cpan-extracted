package Google::RestApi::SheetsApi4::Request::Spreadsheet;

our $VERSION = '0.9';

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

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
