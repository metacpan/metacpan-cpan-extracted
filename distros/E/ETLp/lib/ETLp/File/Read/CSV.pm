use MooseX::Declare;

=head1 NAME

ETLp::File::Read::CSV - audit the execution of an ETLp job

=head1 DESCRIPTION

This class is used to manage the job's audit record

=head1 SYNOPSIS

    use ETLp::File::Read::CSV;

    my $csv = ETLp::File::Read::CSV->new(
        filename    => "/data/comit/final.csv",
        fields      => [qw/id name score/],
        csv_options => {allow_whitespace => 1},
        localize    => 1,
    );
    
    while (my $fields = $csv->get_fields) {
        print $csv->line_counter() .": " . $csv->{name}, "\n";
    };
    
=cut

=head1 METHODS

=head2 new

Create a File object.

Parameters

Hash or hashref consisting of

    * filename: Required. Name  of the file to be opened
    * fields: Required. The fields in the file
    * csv_options. Optional. Settings for parsing the CSV file. See
      Text::CSV documentation
    * localize. Optional. Whether the end of line characters should be
      converted to the native ones
      

Returns

    * a ETLp::File::Read::CSV object
    
=head2 get_fields

Extracts the fields from a file

Parameters

    * None
    
Returns

    * A hashref where each key is populated with the filed value from the
      file record
    
=cut

class ETLp::File::Read::CSV extends ETLp::File::Read {
    use Text::CSV;
    use Data::Dumper;
    use ETLp::Exception;
    
    has 'csv_options' => (is => 'ro', isa => 'HashRef', default => sub { {} });
    has 'fields' => (is => 'ro', isa => 'ArrayRef');
    has 'ignore_field_count' => (is => 'ro', isa => 'Bool', default => 0);

    method get_fields {
        my $line = $self->get_line;
        return unless $line;
        my $csv    = $self->{_csv};
        my $status = $csv->parse($line);

        if ($status) {
            my @columns = $csv->fields;
            my @fields  = @{$self->fields};
            if ((scalar(@columns) != scalar(@fields)) && !($self->ignore_field_count)) {
                my $error =
"The number of data file fields does not match the number of control file fields\n"
                  . "line number: %s\nfields: %s\nline: %s";
                ETLpException->throw(error => sprintf($error,
                    $self->line_counter, join(', ', @fields), $line));
            }

            # Create a hash where the keys are the field names and
            # the values are the parsed columns
            my %rec;
            @rec{@fields} = @columns;
            return \%rec;
        } else {
            my $error = "Error: %s\nline number: %s\nfields: %s\nline: %s";
            ETLpException->throw(error => sprintf($error,
                $csv->error_diag(), $self->line_counter, $self->fields, $line));
        }
    }

    method BUILD {
        $self->logger->debug("CSV options: " . Dumper($self->csv_options));
        $self->{_csv} = Text::CSV->new($self->csv_options) ||\
            die "Cannot use CSV: ".Text::CSV->error_diag ();
    }

}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application
    
=cut
