=pod

=head1 NAME

ETL::Pipeline::Input::File::Table - Sequential input in rows and columns

=head1 SYNOPSIS

  # In the input source...
  use Moose;
  with 'ETL::Pipeline::Input';
  with 'ETL::Pipeline::Input::File';
  with 'ETL::Pipeline::Input::File::Table';
  ...

=head1 DESCRIPTION

CSV (comma separated values) or Excel spreadsheet files represent data in a
table structure. Each row is a record. Each column an individual field. This
role provides some attributes common for this type of data. That way you don't
have to reinvent the wheel every time.

=cut

package ETL::Pipeline::Input::File::Table;

use 5.014000;

use List::AllUtils qw/indexes/;
use Moose::Role;
use String::Util qw/hascontent trim/;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 no_column_names

Tabular data usually has field names in the very first row. This makes it
easier for a human being to read. Sometimes, though, there are no field names.
The data starts on the very first row.

Set B<no_column_name> to B<true> for these cases. Otherwise, the input source
will load your first row of data as field names.

  $etl->input( 'Excel', no_column_names => 1 );

=cut

has 'no_column_names' => (
	default => 0,
	is      => 'ro',
	isa     => 'Bool',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
