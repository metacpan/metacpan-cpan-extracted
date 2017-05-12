package ETLp::File::Validate;

use MooseX::Declare;

=head1 NAME

ETLp::File::Validate - Validate file content

=head1 SYNOPSIS


    use ETLp::File::Validate;

    my $val = ETLp::File::Validate->new(
        data_directory        => '/data/incoming',
        file_config_directory => "$Bin/../conf",
        file_definition       => 'file_def.cfg',
        localize              => 1,
        type                  => 'csv'
    );
    
    my $ret = $val->validate('data.txt');
    
    unless($ret) {
        my @errors = @{$val->get_errors};
        
        foreach my $error (@errors) {
            print $error->{line_number} .": " . $error->{message}, "\n";
        }
    }
    ...

=head1 METHODS

=head2 new

Create a validation object.

Parameters

Hash or hashref consisting of

    * type: Required. The type of file (csv), fixed width
    * data_directory: Optional. The directory where the files to be
      loaded are located.
    * file_config_directory: Optional. The directory where the
      file_defintion file can be found.
    * file_definition: Required. A file that contains a defintion
      of the validation rules. If the file_config_directory parameter
      is not set, then this must be the full path to the defintion file

Returns

    * a ETLp::File::Validate object

=cut

class ETLp::File::Validate {
    use Time::Piece;
    use ETLp::Exception;
    use ETLp::File::Config;

    has 'data_directory'        => (is => 'ro', isa => 'Str');
    has 'file_config_directory' => (is => 'ro', isa => 'Str');
    has 'file_definition' => => (is => 'ro', isa => 'Str', required => 1);
    has 'type'     => (is => 'ro', isa => 'Str',  required => 1);
    has 'localize' => (is => 'ro', isa => 'Bool', default  => 0);
    has 'skip'     => (is => 'ro', isa => 'Int', default  => 0);
    has 'csv_options' => (is => 'ro', isa => 'HashRef', required => 0, default => sub{{}});

    our @errors;

=head2 validate

Validate the file

Parameters

    * The name of the file being validated,
    
Returns

    * Success flag (0 = fail, success = 1)

=cut

    method validate(Str $filename) {

        @errors = ();

        if ($self->data_directory) {
            $filename = $self->data_directory . "/$filename";
        }

        if ($self->type eq 'csv') {
            return $self->_validate_csv($filename);
        } else {
            ETLpException->throw(error => "Unknown file type: " . $self->type);
        }
    }

    # Reads the supplied CSV file and validates each line against the
    # definition
    method _validate_csv(Str $filename) {

        require ETLp::File::Read::CSV;

        my $csv = ETLp::File::Read::CSV->new(
            filename    => $filename,
            fields      => $self->config->fields,
            csv_options => $self->csv_options,#{allow_whitespace => 1},
            localize    => $self->localize,
            skip        => $self->skip
        );

        # Loop through each record in the file, and validate it
        # against the rules
        my $line_counter = 1;
        while (my $fields = $csv->get_fields) {
            $self->_validate_record($line_counter++, $fields);
        }

        my $ret_status = (@errors > 0) ? 0 : 1;
          return $ret_status;
    }

# Validate a record's values against its definitions

    method _validate_record(Int $line_counter, HashRef $fields) {
        my $rules = $self->config->rules;

        LOOP:
        foreach my $field_name (@{$self->config->fields}) {
            my $value    = $fields->{$field_name};
            my $nullable = $rules->{$field_name}->{nullable};
            my @rules =
              (ref $rules->{$field_name}->{rule} eq 'ARRAY')
              ? @{$rules->{$field_name}->{rule}}
              : ($rules->{$field_name}->{rule});

            # Make sure that a mandatory field has a value;
            if (   (uc $rules->{$field_name}->{nullable} eq 'N')
                && ($value =~ /^$/))
            {
                _add_error(
                    line_number => $line_counter,
                    field_name  => $field_name,
                    field_value => $value,
                    message     => 'Mandatory field missing value',
                );

                next LOOP;
            }

            # No other checks required unless we have a value
            next LOOP unless $value;

            for (my $j = 0 ; $j < @rules ; $j++) {
                # Range check means that the value is a number
                if ($rules[$j] =~ /^range\(.*\)$/i) {

                    unless (_is_number($value)) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Value must be an a number",
                        );

                        next LOOP;
                    }

                    unless ($value =~ /^[-+]?\d*\.?\d*$/) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => 'Must be a number',
                        );

                        next LOOP;
                    }
                }
                # Check minimum and maximum range values
                if ($rules[$j] =~ /^range\(\s*([-+]?\d+),\s*([-+]?\d+)\s*\)$/i)
                {
                    my $lower = $1;
                    my $upper = $2;

                    unless (_is_number($value)) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Value must be an a number",
                        );

                        next LOOP;
                    }

                    unless (($value >= $lower) && ($value <= $upper)) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message => 'Value outside of range: ' . $rules[$j],
                        );

                        next LOOP;
                    }
                }
                # Upper range check
                elsif ($rules[$j] =~ /^range\(\s*,\s*([-+]?\d+)\s*\)$/i) {
                    my $upper = $1;

                    unless (_is_number($value)) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Value must be an a number",
                        );

                        next LOOP;
                    }

                    unless ($value <= $upper) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Value must be <= $upper",
                        );
                    }
                }
                # Lower range check
                elsif ($rules[$j] =~ /^range\(\s*([-+]?\d+)\s*,\s*\)$/i) {
                    my $lower = $1;

                    unless (_is_number($value)) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Value must be an a number",
                        );

                        next LOOP;
                    }

                    unless ($value >= $lower) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Value must_be >= $lower",
                        );
                    }
                }
                # varchar check
                elsif ($rules[$j] =~ /^varchar\((\d+)\)$/i) {
                    my $max_length   = $1;
                    my $value_length = length($value);

                    unless ($value_length <= $max_length) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message => "Length must be less than or equal to "
                              . $max_length
                              . " characters",
                        );
                    }
                }
                # Integer check
                elsif (uc $rules[$j] eq 'INTEGER') {
                    unless ($value =~ /^[-+]?\d+$/) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Value must be an integer",
                        );
                    }
                }
                # Float check
                elsif (uc $rules[$j] eq 'FLOAT') {
                    unless (_is_number($value)) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Value must be a floating number",
                        );
                    }
                }
                # Date check
                elsif ($rules[$j] =~ /^date\('?(.*)'?\)$/i) {
                    my $pattern = $1;

                    eval { Time::Piece->strptime($value, $pattern); };

                    if ($@) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Invalid date for pattern: $pattern",
                        );
                    }
                }
                # Regex check
                elsif ($rules[$j] =~ /^qr\/.*\//i) {
                    my $regex = eval($rules[$j]);
                    if ($value !~ $regex) {
                        _add_error(
                            line_number => $line_counter,
                            field_name  => $field_name,
                            field_value => $value,
                            message     => "Value does not match pattern "
                              . $rules[$j],
                        );
                    }
                } else {
                    _add_error(
                        line_number => $line_counter,
                        field_name  => $field_name,
                        field_value => $fields->{field_name},
                        message     => "Unknown pattern " . $rules[$j],
                    );
                }
            }
        }
    };
    
    # Add an error to the stack
    sub _add_error {
        my %args = @_;
        push @errors, \%args;
    }
    
    # Is the value a number? Used for range checks
    sub _is_number {
        my $value = shift;
        return $value =~ /^[-+]?\d*\.?\d*$/;
    }

=head2 get_errors

Returns a list of error messages

Parameters

    * None
    
Returns

    * An arrayref of hashrefs. Each array elemnet is an error. Each
      hashref contains the error details
      
          o line_number: The line number where the error occurred
          o field_name: The name of the field that failed validated
          o field_value: The value in the field
          o message: The error message
    
=cut

    sub get_errors {
        return \@errors;
    }

=head2 config

Returns the parsed configuration used by the validation

Parameters

    * None
    
Returns

    * a ETLp::File::Config object

=cut

    method config {
        return $self->{_config};
    }
    
    method BUILD {    
        $self->{_config} = ETLp::File::Config->new(
            directory  => $self->file_config_directory,
            definition => $self->file_definition,
        );    
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application
    
=cut
