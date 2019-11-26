package Google::RestApi::SheetsApi4::Range::All;

use strict;
use warnings;

our $VERSION = '0.4';

use 5.010_000;

use autodie;
use Type::Params qw(compile_named);
use Types::Standard qw(HasMethods);

no autovivification;

use parent 'Google::RestApi::SheetsApi4::Range';

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;

  state $check = compile_named(
    worksheet => HasMethods[qw(api worksheet_name)],
  );
  my $self = $check->(@_);

  return bless $self, $class;
}

sub range { shift->worksheet_name(); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range::All - Represents an the Range of an entire Worksheet.

=head1 DESCRIPTION

A Range::All object modifies the behaviour of the parent Range object
to return the entire worksheet as the range.

THIS IS CURRENTLY JUST A PLACEHOLDER FOR THE OBJECT AND HAS NOT BEEN
TESTED AS YET.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
