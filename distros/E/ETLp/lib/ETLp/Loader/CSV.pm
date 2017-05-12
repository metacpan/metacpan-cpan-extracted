package ETLp::Loader::CSV;

use MooseX::Declare;

=head1 NAME

ETLp::Loader::CSV -  Load a CSV file's content into a table

=head1 DESCRIPTION

This class is used to manage the job's audit record

=head1 SYNOPSIS

    use ETLp::Loader::CSV;

    my $loader = ETLp::Loader::CSV->new(
        table => 'table_name',
        columns => [qw/col1 col2 col3/]
        directory => '/data/incoming',
    );
    
    my $status = $loader->load('data.csv');
    
    unless ($status) {
        die $status->error;
    }
    
    print "Rows loaded: " $loader->rows_loaded;
    
=cut

class ETLp::Loader::CSV with ETLp::Role::Config {
    
    use ETLp::File::Read::CSV;
    use Data::Dumper;
    use File::Basename;
    use Convert::NLS_DATE_FORMAT qw(posix2oracle);
    use DBI::Const::GetInfoType;
    use ETLp::Exception;
    use Try::Tiny;
    
    has 'directory' => (is => 'ro', isa => 'Str');
    has 'table'     => (is => 'ro', isa => 'Str', required => 1);
    has 'columns'   => (is => 'ro', isa => 'ArrayRef', required => 1);
    has 'rules'     => (is => 'ro', isa => 'HashRef', required => 0);
    has 'localize'  => (is => 'ro', isa => 'Int', default => 0);
    has 'error'     => (is => 'rw', isa => 'Str');
    has 'file_id'   => (is => 'ro', isa => 'Int', required => 1);
    has 'skip'      => (is => 'ro', isa => 'Int', required => 0, default => 0);
    has 'ignore_field_count' => (is => 'ro', isa => 'Bool', default => 0);
    has 'csv_options' => (is => 'ro', isa => 'HashRef', required => 0,
                          default => sub{{allow_whitespace => 1}});
    
=head1 METHODS

=head2 new

Create a loader, specifying the characteristics

Parameters

    * table: Required. The table the data is being loaded into
    * columns: Required. The columns in the table that we are inserting into.
      These should match the name of the file field names
    * directory: Optional. The directory where the load files are located.
    * localize: Optional. Whether to localize the input files (i.e. process
      the input file setting the appropriate newline character for the
      host OS)
      
Returns

    * A ETLp::Loader::CSV object

=head2 load

Load a file into the specified table. If the directory attibute is set
then this should be a relative path.

Parameters

    * The name of the file to be loaded
    
Returns

    * Status. 1 - Success, 0 = failure

=cut

    method load (Str $filename) {
        my @columns  = @{$self->columns};

        $self->{_rows_loaded} = 0;
        $self->error('');
        
        my $error_flag = 1;

        try {
            my $directory = $self->directory;

            unless ($directory) {
                $directory = dirname($filename);
                $filename  = basename($filename);
            };

            my $csv = ETLp::File::Read::CSV->new(
                directory   => $directory,
                filename    => $filename,
                localize    => $self->localize,
                fields      => $self->columns,
                skip        => $self->skip,
                ignore_field_count => $self->ignore_field_count,
                csv_options => $self->csv_options,
            );

            $self->logger->debug("SQL: $self->{_sql}");
            $self->logger->debug("Columns: " . Dumper(\@columns));

            my $sth = $self->dbh->prepare($self->{_sql});

            my $row_counter = 0;

            while (my $fields = $csv->get_fields) {
                my @vals = map($fields->{$_}, @columns);
                $sth->execute(@vals);
                $self->{_rows_loaded}++;
            }

            $sth->finish;

            $self->dbh->commit;
        } catch {
            my $error = $_;
            $self->dbh->rollback;

            $self->{_rows_loaded} = 0;
            $self->error($error);
            $error_flag = 0;
        };

        return $error_flag;
    }
    
=head2 rows_loaded

Returns the number of rows inserted by the last load

Parameters

    * None
    
Returns

    * An integer

=cut

    method rows_loaded {
        return $self->{_rows_loaded};
    }
    
    # Construct the SQL statement that will perform the insert
    method _construct_sql {
    
        my @columns      = @{$self->columns};
        my $column_rules = $self->rules;
        my $placeholders;
        
        # deal with the case where the column is a date and we need to cast the
        # date string
    
        if ($column_rules) {
    
            my @placeholders;
            $self->logger->debug("Columns: " . Dumper(\@columns));
            foreach my $column (@columns) {
                $self->logger->debug("Column: $column");
                my $date_flag = 0;
                my $rules     = $column_rules->{$column}->{rule};
                $rules = [$rules] unless ref $rules eq 'ARRAY';
                foreach my $rule (@$rules) {
                    if ($rule =~ /^date\('?(.*)'?\)$/i) {
                        my $posix_pattern = $1;
                        $self->logger->debug("Date pattern: $posix_pattern");
                        my $db_date_pattern =
                          $self->_get_db_date_formatter($posix_pattern);
                        $self->logger->debug("DB Conversion: " .
                            $db_date_pattern);
                        push @placeholders, $db_date_pattern;
                        $date_flag = 1;
                    }
                }
                push @placeholders, '?' unless $date_flag;
            }
    
            $self->logger->debug("Placeholders: " . Dumper(\@placeholders));
            $placeholders = join(',', @placeholders);
        } else {
            $placeholders = join(', ', split(//, '?' x @columns));
        }
    
        return
            'insert into '
          . $self->table . '('
          . join(', ', @columns, 'file_id')
          . ') values ('
          . $placeholders . ', '. $self->file_id.')';
    }
    
    # Each vendor has a dfferent wasy of handling dates. This method provides
    # the specific SQL to deal with date formatting
    method _get_db_date_formatter(Str $posix_pattern) {    
        $self->logger->debug('POSIX Pattern: ' . $posix_pattern);
    
        my $driver = lc $self->dbh->get_info($GetInfoType{SQL_DBMS_NAME});
    
        if (($driver eq 'oracle') || ($driver eq 'postgresql')){
            return "TO_DATE(?, '" . posix2oracle($posix_pattern) . "')";
        } elsif ($driver eq 'mysql') {
            return "STR_TO_DATE(?,'$posix_pattern')";
        } elsif ($driver eq 'sqlite') {
            return '?'
        }
        ETLpException->throw(error => "Unknown Database Driver: $driver");
    }
        
    method BUILD {
        $self->{_sql}         = $self->_construct_sql;
        $self->{_rows_loaded} = 0;
        $self->logger->debug("Rules " . Dumper($self->rules));
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application
    
=cut

