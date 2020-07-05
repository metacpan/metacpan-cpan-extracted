package MYDan::API::AntDen;
use strict;
use warnings;

use base qw( MYDan::API );
our $URI = "/api/antdencli";

sub submitjob
{
    my ( $self, %data ) = @_;
    return $self->post( "$URI/submitJob", %data );
}

sub listjob
{
    my ( $self, $owner ) = @_;
    return $self->get( "$URI/listJob?owner=$owner" );
}

sub info
{
    my ( $self, $jobid, $owner ) = @_;
    return $self->get( "$URI/jobinfo/$jobid?owner=$owner" );
}

sub stop
{
    my ( $self, $jobid, $owner ) = @_;
    return $self->get( "$URI/jobstop/$jobid?owner=$owner" );
}

sub taskinfo
{
    my ( $self, $taskid ) = @_;
    return $self->get( "$URI/taskinfo/$taskid" );
}

sub resources
{
    my ( $self, $owner ) = @_;
    return shift->get( "$URI/resources?owner=$owner" );
}

1;
