use strict;
use 5.010;

package FusqlFS::Backend::MySQL;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Backend::Base';

sub init
{
    my $self = shift;

    my $charset = $self->{charset}||'utf8';
    $self->do('SET character_set_results = ?'   , $charset);
    $self->do('SET character_set_client = ?'    , $charset);
    $self->do('SET character_set_connection = ?', $charset);

    $self->autopackages(
        'tables',
        'users',
        'procedures',
        'functions',
        'variables');
}

sub dsn
{
    my $self = shift;
    return 'mysql:'.$self->SUPER::dsn(@_);
}

1;

