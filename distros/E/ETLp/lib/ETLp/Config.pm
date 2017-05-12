package ETLp::Config;

use MooseX::Declare;

=head1 NAME

ETLp::Config - the basic configuration setting for ETLp

=head1 DESCRIPTION

This is a singleton class that provides the Framework's configuration
settings to all interested classes in the framework

=cut

class ETLp::Config {
    use MooseX::Singleton;
    has 'dbh'    => (is => 'rw', isa => 'DBI::db');
    has 'logger' => (is => 'rw', isa => 'Log::Log4perl::Logger');
    has 'schema' => (is => 'rw', isa => 'ETLp::Schema');
    has 'audit'  => (is => 'rw', isa => 'ETLp::Audit::Job');
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut

1;
