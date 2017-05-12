package Enbld::Definition::Brokenapp;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'BrokenApp';
    $self->{defined}{WebSite}           =   'http://www.example.com/';
    $self->{defined}{DistName}          =   'BrokenApp';
    $self->{defined}{VersionForm}       =   '\d\.\d';
    $self->{defined}{Extension}         =   'tar.gz';
    $self->{defined}{Dependencies}      =   undef,
    $self->{defined}{DownloadSite}      =   'http://www.example.com/';

    $self->{defined}{CommandConfigure}  =   undef;
    $self->{defined}{CommandTest}       =   undef;
    $self->{defined}{CommandInstall}    =   undef;

    return $self;
}

1;
