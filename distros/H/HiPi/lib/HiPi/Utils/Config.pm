#########################################################################################
# Package        HiPi::Utils::Config
# Description  : Config File Wrapper
# Copyright    : Copyright (c) 2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Utils::Config;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use File::Path ( );

use JSON;
use Try::Tiny;
use Storable;
use Carp;

__PACKAGE__->create_ro_accessors( qw( configclass filepath default ) );
__PACKAGE__->create_accessors( qw( config _configkey ) );

our $VERSION ='0.81';

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        configclass => 'hipi',
        default    => {},
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    $params{'_configkey'} = '';
    
    $params{default}->{'hipi-config-version'} = $VERSION;
        
    my $fileroot = ( $> ) ? qq($ENV{HOME}/.hipi-perl) : '/etc/hipi-perl';
    my $filename = ( $> ) ? 'user.conf' : 'global.conf';
    
    my $dirpath = qq($fileroot/$params{configclass});
    
    File::Path::make_path($dirpath , { mode => 0700 } ) unless( -d $dirpath );
    
    $params{filepath} = $dirpath . '/' . $filename;
    
    my $self = $class->SUPER::new( %params );
    
    if( -f $self->filepath ) {
        $self->read_config;
        # update any new defaults 
        my $conf = $self->config;
        my $updatedefaults = 0;
        for my $itemname ( keys %{ $params{default} } ) {
            if( !exists( $conf->{$itemname} ) || !defined($conf->{$itemname}) ) {
                $conf->{$itemname} = $params{default}->{$itemname};
                $updatedefaults = 1;
            }
        }
        $self->write_config if $updatedefaults;
        
    } else {
        $self->config( $self->default );
        $self->write_config;
    }
    
    return $self;
}

sub read_config {
    my $self = shift;
    open ( my $fh, '<:encoding(UTF-8)',  $self->filepath ) or croak( qq(failed to open config file : $!) );
    read( $fh, my $input, -s $fh);
    close( $fh );
    my $json = JSON->new;
    my $conf = try {
        my $decoded = $json->decode( $input );
        return $decoded;
    } catch {
        carp q(failed to decode configuration ) . $_;
        return { config_ok => 0 };
    };
    
    $Storable::canonical = 1;
    my $ckey = Storable::nfreeze( $conf );
    $Storable::canonical = 0;
    $self->_configkey( $ckey );
    $self->config( $conf );
    return 1;
}

sub write_config {
    my $self = shift;
    
    $Storable::canonical = 1;
        
    my $ckey = Storable::nfreeze( $self->config );
    $Storable::canonical = 0;
    if($ckey eq $self->_configkey) {
        # no need to write an unchanged config
        return 1;
    }
    
    $self->config->{epoch} = time();
    $ckey = Storable::nfreeze( $self->config );
    $self->_configkey( $ckey );
    
    open ( my $fh, '>:encoding(UTF-8)',  $self->filepath ) or croak( qq(failed to open config file : $!) );
    my $json = JSON->new;
    my $output = try {
        my $encoded = $json->pretty->canonical->encode( $self->config );
        return $encoded;
    } catch {
        carp q(failed to encode configuration ) . $_;
        return '';
    };
    if( $output ) {
        print $fh $output;
    }
    close( $fh );
    return 1;
}

sub DESTROY {
    # don't call super
    my $self = shift;
    if( $threads::threads ) {
        if( threads->tid == 0 )  {
            $self->write_config;
        }
    } else {
       $self->write_config;
    }
}


1;

__END__