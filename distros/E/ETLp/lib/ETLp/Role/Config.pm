#package ETLp::Role::Config;

use MooseX::Declare;

=head1 NAME

ETLp::Role::Config - the basic configuration setting for ETLp

=head1 DESCRIPTION

This role provides a wrapper around ETLp::Config. It's purpose
is top provide simple access to the configuration setting

=head1 METHODS

=head2 config

Return the application configuration hash

=head2 dbh

Return the database handle

=head2 logger

Return the Log4perl logger

=head2 audit

Return the job auditer (ETLp::Audit::Job object)

=cut

role ETLp::Role::Config {
    use ETLp::Config;
    
    #method config {
    #    return ETLp::Config->config;
    #}
    
    method audit {
        return ETLp::Config->audit;
    }
    
    method dbh {
        return ETLp::Config->dbh;
    }
    
    method logger {
        return ETLp::Config->logger;
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut

1;

