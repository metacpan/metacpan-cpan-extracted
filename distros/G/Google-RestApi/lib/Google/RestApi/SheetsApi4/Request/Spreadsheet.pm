package Google::RestApi::SheetsApi4::Request::Spreadsheet;

use strict;
use warnings;

our $VERSION = '0.2';

use 5.010_000;

use autodie;
use Type::Params qw(compile);
use Types::Standard qw(Str);

no autovivification;

use parent "Google::RestApi::SheetsApi4::Request";

do 'Google/RestApi/logger_init.pl';

sub spreadsheet_id { die "Pure virtual function 'spreadsheet_id' must be overridden"; }

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
