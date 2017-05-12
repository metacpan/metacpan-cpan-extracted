package Db::Mediasurface;
$VERSION = '0.03';
use strict;
use Carp;
use DBI;
use Db::Mediasurface::ReadConfig;

sub new
{
    my ($class,%arg) = @_;

    my $self = {
	_config_file => $arg{config_file} || undef,
	_config      => $arg{config}      || undef,
	_version     => undef,
	_dbh         => undef
	};

    croak('you must supply either a Db::Mediasurface::ReadConfig object or the path to a configuration file')
	unless ((defined $self->{_config}) or (defined $self->{_config_file}));

    if (defined $self->{_config_file})
    {
	$self->{_config} = Db::Mediasurface::ReadConfig->new( path=>$self->{_config_file} );
    }

    bless $self, $class;
}

sub version
{
    my $self = $_[0];
    unless (defined $self->{_version})
    {
	my $sql = "SELECT schemaversion FROM systemdefaults";
	$self->_dbi_connect;
	my $sth = $self->{_dbh}->prepare($sql) or carp("Database prepare error: $DBI::errstr");
	$sth->execute or carp("Database execute error: $DBI::errstr");
	($self->{_version}) = ($sth->fetchrow_array);
	$sth->finish();
    }
    return $self->{_version};
}

sub _dbi_connect
{
    my $self = $_[0];
    unless (defined $self->{_dbh}){
	my $data_source = 'DBI:Oracle:';
	my $username = $self->{_config}->get_username;
	my $password = $self->{_config}->get_password;
	my $attributes = {};
	$self->{_dbh} = DBI->connect( $data_source, $username, $password, $attributes )
	    or croak("Couldn't connect to database: $DBI::errstr");
    }
}

1;

=head1 NAME

Db::Mediasurface - manipulates a Mediasurface database.

=head1 VERSION

This document refers to version 0.03 of DB::Mediasurface, released August 3, 2001.

=head1 SYNOPSIS

    use Db::Mediasurface;
    $path = '/opt/ms/3.0/etc/ms.properties';
    $ms = Db::Mediasurface->new( config_file=>$path );
    print ("Schema version: ".$ms->version."\n");

    use Db::Mediasurface;
    use Db::Mediasurface::ReadConfig;
    $path = '/opt/ms/3.0/etc/ms.properties';
    $config = Db::Mediasurface::Readconfig->new( config=>$path );
    $ms = Db::Mediasurface->new( config=>$config );
    print ("Schema version: ".$ms->version."\n");

=head1 DESCRIPTION

=head2 Overview

Db::Mediasurface is a wrapper for most other Db::Mediasurface:: modules. At present, only the new() and version() methods are supported.

=head2 Constructor

=over 4

=item $ms = Db::Mediasurface->new( config=>$config_object );

=item $ms = Db::Mediasurface->new( config_file=>$path2config );

Create a new Db::Mediasurface object by supplying either the path to a valid Mediasurface configuration file (usually named ms.properties), or a Db::Mediasurface::ReadConfig object.

=back

=head2 Methods

=over 4

=item $ms_version = $ms->version;

Returns the database schema version.

=back

=head1 AUTHOR

Nigel Wetters (nwetters@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2001, Nigel Wetters. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.
