package Enbld::Definition::Testapp;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'TestApp';
    $self->{defined}{WebSite}           =   'http://www.example.com/';
    $self->{defined}{DistName}          =   'TestApp';
    $self->{defined}{VersionForm}       =   '\d\.\d';
    $self->{defined}{Extension}         =   'tar.gz';
    $self->{defined}{Dependencies}      =   undef,
    $self->{defined}{DownloadSite}      =   'http://www.example.com/';
    $self->{defined}{PatchFiles}        =
        [ 'http://www.example.com/TestAppPatch.txt' ];

    $self->{defined}{TestAction}        =   'test';

    return $self;
}

1;
