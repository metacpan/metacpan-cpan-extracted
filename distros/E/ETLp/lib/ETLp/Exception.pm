package ETLp::Exception;

use MooseX::Declare;

=head1 NAME

ETLp::Exception - ETLp Exception Class

=head1 SYNOPSIS

    use MooseX::Declare
    class My::ETL {
        use ETLp::Exception;
        use Try::Tiny
        
        method do_stuff {
            unless ($self->continue) {
                ETLpException->throw(error => "Can't continue");
            }
        }
        
        method call_do_stuff {
            try {
                do_stuff
            } catch {
                print "Error $_";
                $_->rethrow;
            }
        }
    }
    
=head1 DESCRIPTION

ETLP::Exception provides ETLpException, an Exception:Class
object. Because it can be stringified, it can simply be printed
or inserted into a database.

The exception can also be sub-classed if required:

    class My::ETL::CSV {
        use Exception::Class (
            ETLpExceptionCSV => {
                isa => 'ETLpException',
                fields => [qw/error_code short_name/]
            }
        );
        
        method load_csv (Str $filename) {
            $self->insert_into_db($filename) || ETLpExceptionCSV->throw(
                error => 'Unable to insert into DB:$!',
                error_code => 29,
                short_name => 'insertion error',
            );
        }
    }
    
    # In some different class
    
    my $loader = My::ETL::CSV->new()
    
    try {
        $loader->load_csv
    } catch {
        my $error = $_;
        $self->logger->error($error->error_code . ':' . $error->error);
        $error->rethrow;
    }
    
=cut

class ETLp::Exception {
    use Exception::Class (
        'ETLpException'
    );
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application
