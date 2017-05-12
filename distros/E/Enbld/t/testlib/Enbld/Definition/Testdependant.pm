package Enbld::Definition::Testdependant;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'TestApp';
    $self->{defined}{WebSite}           =   'http://www.example.com/';
    $self->{defined}{DistName}          =   'TestDependant';
    $self->{defined}{VersionForm}       =   '\d\.\d';
    $self->{defined}{Extension}         =   'tar.gz';
    $self->{defined}{Dependencies}      =   sub { return [ 'testapp' ] },
    $self->{defined}{DownloadSite}      =   'http://www.example.com/';

    $self->{defined}{TestAction}        =   'test';

    return $self;
}

1;
