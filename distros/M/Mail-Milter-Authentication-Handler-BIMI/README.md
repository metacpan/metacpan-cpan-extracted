# NAME

    Authentication Milter - BIMI Module

# DESCRIPTION

Module implementing the BIMI standard checks.

This handler requires the DMARC handler and its dependencies to be installed and active.

# CONFIGURATION

        "BIMI" : {                                      | Config for the BIMI Module
                                                        | Requires DMARC
        },

# SYNOPSIS

# AUTHORS

Marc Bradshaw <marc@marcbradshaw.net>

# COPYRIGHT

Copyright 2017

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

        my $dmarc = $self->get_dmarc_object();
        return if ( $self->{'failmode'} );
        my $header_domain = $self->get_domain_from( $value );
        eval { $dmarc->header_from( $header_domain ) };
        if ( my $error = $@ ) {
            $self->log_error( 'DMARC Header From Error ' . $error );
            $self->add_auth_header('dmarc=temperror');
            $self->metric_count( 'dmarc_total', { 'result' => 'temperror' } );
            $self->{'failmode'} = 1;
            return;
        }
