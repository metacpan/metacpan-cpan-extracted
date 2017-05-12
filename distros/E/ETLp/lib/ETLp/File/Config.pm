package ETLp::File::Config;

use MooseX::Declare;

=head1 NAME

ETLp::File::Config - Parse the file confgiuration defintions

=head1 SYNOPSIS

    use ETLp::File::Config;

    my $file_conf = ETLp::File::Config->new(
        directory => "$Bin/../conf",
        definition => 'file_def.cfg',
    );
    
    # Get the fields from the config file:
    my @fields = @{$file_conf->fields};
    
ETLp::File::Config parses data file definitions. Defintions are specified in
files and consist of the following components separated by whitespace:

    * field name - the name of the field
    * nullable - whether the field is allows nulls (Y or N)
    * validation rules:
    
        o A regex pattern, specified as qr/<regex>/
        o Varchar(n). String up to n characters.
        o Integer. A positive or negative integer.
        o Real. A real number.
        o Date(<POSIX PATTERN>). A valid date with the format specified
          as a POSIX pattern
        o range(n, m). A numeric range from n to m. If n is not specified
          there is no lower limit. If m is not specified, there is no
          upper limit
          
Multiple validation rules can be specified per field - simply separate
with a semi-colon.

Example Configuration entries

    custname   N    varchar(20)
    cost       Y    integer
    phone      Y    qr/^\d{3}-\d{4}$/
    city       N    qr/^(Auckland|Wellington)$/
    rec_date   N    date(%Y-%n-%d %H:%M%S)   
    period     N    range(1,50); integer
    
Individual rules can be enclosed in double-quotes, which will be
required if any indvidual rule contains a semi-colon:

    contrived_field N "qr/\d;\s{3}/"
    
Comments can be specified with a hash

    # This is a line comment
    custname   N    varchar(20) # And this is a field comment

=head1 METHODS

=head2 new

Create a Config object.

Parameters

Hash or hashref consisting of

    * directory: Optional. The directory where the
      file_defintion file can be found.
    * definition: Required. A file that contains a defintion
      of a file. 

Returns

    * a ETLp::File::Validate object
    
=cut

class ETLp::File::Config  with ETLp::Role::Config {
    use Text::CSV;
    use ETLp::Exception;
    use Data::Dumper;
    
    has 'directory'  => (is => 'ro', isa => 'Str', required => 0);
    has 'definition' => (is => 'ro', isa => 'Str', required => 1);
    has 'fields'     => (is => 'rw', isa => 'ArrayRef');
    has 'rules'      => (is => 'rw', isa => 'HashRef');
    
    # Makes sure that the rule is actually valid.
    method _check_rule(Str $rule) {
        ETLpException->throw(error => "unknown rule $rule")
          unless (($rule =~ /^qr\/.*\/$/)
            or ($rule =~ /^varchar\((\d+)\)$/i)
            or (lc $rule eq 'integer')
            or ($rule =~ /date\(\s*'?.*\'?\s*\)/i)
            or (lc $rule eq 'float')
            or ($rule =~ /^range\(\s*\d*\s*,\s*\d*\s*\)$/i));
    }
    
    # parses the confguration file
    method _parse_config(Str $definition) {
        my (@fields, %fields);
    
        open(my $fh, '<', $definition) ||
            ETLpException->throw(error => "Unable to open $definition: $!");
    
        my $csv = Text::CSV->new({sep_char => ';', allow_whitespace => 1});
    
        while (my $line = <$fh>) {
            my $parsed_line = $line;
            $parsed_line =~ s/#.*$//;
            next if $parsed_line =~ /^$/;
    
            my $parsed_rule;
            my ($field, $nullable, $rule) =
              ($parsed_line =~ /^\s*(\S+)\s+(\S+)\s+(\S.*?)\s*$/);
    
            unless ($field && $nullable && $rule) {
                ETLpException->throw(error => "Config file must provide "
                      . "the field name, nullable flag and validation rule.\n"
                      . "line: $line");
            }
    
            # Check if multiple rules have been specified for a field
            # Use Text::CSV to deconstruct in case there are quotes,
            # embedded semi-colons or any other nasties
            if ($rule =~ /;/) {
                my $status = $csv->parse($rule);
                unless ($status) {
                    ETLpException->throw(error =>
                        sprintf("error: %s\nvalue: %s\nline: %s",
                        "" . $csv->error_diag(), $rule, $line));
                }
                my @rules = $csv->fields;
                $rule = \@rules if (@rules > 1);
            }
    
            if (ref $rule eq 'ARRAY') {
                $self->_check_rule($_) foreach @$rule;
            } else {
                $self->_check_rule($rule);
            }
    
            if ($nullable !~ /^[YyNn]$/) {
                ETLpException->throw(error =>
                    sprintf("Nullable must be Y or N\nvalue: %s\nline: %s",
                    $nullable, $line));
            }
    
            push @fields, $field;
    
            $fields{$field} = {
                nullable => uc $nullable,
                rule     => $rule,
            };
        }
        
        $self->logger->debug("Rules: " . Dumper(\%fields));
    
        $self->fields(\@fields);
        $self->rules(\%fields);
    }
    
    # Automatically called after "new"
    method BUILD {
        my $definition = $self->definition;
    
        if ($self->directory) {
            $definition = $self->directory . "/$definition";
        }
    
        $self->_parse_config($definition);
    }
    
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application
    
=cut

