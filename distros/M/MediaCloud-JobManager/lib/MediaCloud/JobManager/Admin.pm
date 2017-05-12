
=head1 NAME

C<MediaCloud::JobManager::Admin> - administration utilities.

=cut

package MediaCloud::JobManager::Admin;

use strict;
use warnings;
use Modern::Perl "2012";

use MediaCloud::JobManager;
use MediaCloud::JobManager::Configuration;

sub show_jobs($)
{
    my $config = shift;

    unless ( $config )
    {
        die "Configuration is undefined.";
    }

    return $config->{ broker }->show_jobs();
}

sub cancel_job($$)
{
    my ( $config, $job_id ) = @_;

    unless ( $config )
    {
        die "Configuration is undefined.";
    }

    return $config->{ broker }->cancel_job( $job_id );
}

sub server_status($)
{
    my $config = shift;

    unless ( $config )
    {
        die "Configuration is undefined.";
    }

    return $config->{ broker }->server_status();
}

sub workers($)
{
    my $config = shift;

    unless ( $config )
    {
        die "Configuration is undefined.";
    }

    return $config->{ broker }->workers();
}

1;
