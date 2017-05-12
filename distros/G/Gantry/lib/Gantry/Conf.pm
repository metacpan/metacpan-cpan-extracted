package Gantry::Conf; 

#####################################################################
# 
#  Name        :    Gantry::Conf 
#  Author      :    Frank Wiles <frank@revsys.com> 
#
#  Description :    This is the module used by the Gantry programmer
#                   to setup the Gantry auto-configuration and to
#                   retrieve the configuration for a particular 
#                   instance of the application
#
#                   While this configuration system is packaged with
#                   Gantry, it strives to be entirely independant. 
#
#####################################################################

use strict;
use warnings; 

use Carp qw( croak ); 
use Config::General; 
use Hash::Merge qw( merge ); 

# Dispatch table
my %dispatch = (
    PerlSetVar      => '_configure_set_var',
    ParamBuilder    => '_configure_parambuilder',
    FlatFile        => '_configure_flat_file',
    SQL             => '_configure_sql',
    HTTP            => '_configure_http',
    Default         => '_configure_main_conf',
);
our %main_config;

sub import {
    my ( $class, @options ) = @_;
    my $cfg;

    foreach (@options) {
        if ( /^-Config=(.*?)$/ ) {
            my $file = $1;

            _check_file( $class, $file );

            $cfg = Config::General->new(
                -ConfigFile         =>  $file,
                -UseApacheInclude   =>  1,
                -IncludeGlob        =>  1,
                -IncludeDirectories =>  1,
                -IncludeRelative    =>  1,
            );

            %main_config = $cfg->getall;
        }
    }
}

#------------------------------------------------
# new 
#------------------------------------------------
# This is used to build our configuration object
# and to allow sub-classing of Gantry::Conf 
#------------------------------------------------
sub new { 
    my $class   =   shift; 
    my $self    =   {}; 

    bless( $self, $class ); 

    return( $self ); 

} # END new 

#------------------------------------------------
# retrieve
#------------------------------------------------
# This retrieves the configuration for a
# particular "instance" of an application and
# returns a hash reference with all of the
# configuration options 
#------------------------------------------------
sub retrieve { 
    my $class       =   shift; 
    my $params      =   shift;

    croak "Gantry::Conf ERROR: No parameter hash given to retrieve"
        unless ( defined $params and ref( $params ) eq 'HASH' );

    # Die if we aren't given an instance 
    croak "Gantry::Conf ERROR: No instance given to retrieve()"
        unless ( $params->{ instance } );

    my $self = Gantry::Conf->new; 

    # Use /etc/gantry.conf if no other file is given 
    my $config_file = ( $params->{ config_file } ) || '/etc/gantry.conf';

    # Retrieve the actual configuration 
    $self->_load_configuration(
            $params->{ instance },
            $config_file,
            $params->{ location },
            $params->{ reload_config },
    ); 

    # Return our configuration 
    return( $$self{__config__} );

} # END retrieve

#------------------------------------------------
# _load_configuration 
#------------------------------------------------
# This retrieves our instance information from
# /etc/gantry.conf 
#------------------------------------------------
sub _load_configuration { 
    my $self            =   shift; 
    my $instance        =   shift; 
    my $file            =   shift; 
    my $location        =   shift;
    my $reload_config   =   shift;

    # Make sure our file is there and readable 
    $self->_check_file( $file, 'readonly' ); 

    # Get a Config::General object and have it read our configuration
    # filename. 
    #
    # We set these options: 
    #   -UseApacheInclude       to allow "include /etc/foo.conf" from within
    #                           a config file 
    #
    #   -IncludeGlob            to allow a user to do this in their main conf
    #                                include /etc/gantry.d/*.conf
    #
    #   -IncludeDirectories     to allow a user to include a directory of 
    #                           files without a glob, it loads them in ASCII
    #                           order 
    #
    #   -IncludeRelative        to allow including relative files 
    #
    
    # Retrieve the config if it has not already been loaded
    # or if a config reload is being forced.
    if ( (! %main_config) or $reload_config ) {
        my $cfg         = Config::General->new( 
                                    -ConfigFile         =>  $file,
                                    -UseApacheInclude   =>  1,
                                    -IncludeGlob        =>  1,
                                    -IncludeDirectories =>  1,
                                    -IncludeRelative    =>  1,
                          );

        %main_config = $cfg->getall;
    }

    # Look for the instance 
    if( !$main_config{'instance'}{$instance} ) { 
        croak "Gatry::Conf ERROR: Unable to find '$instance'"; 
    }

    # Store this to reduce hash lookups
    my $instance_ref  = $main_config{'instance'}{$instance};

    # Handle all ConfigVia statements
    my $configure_via = $$instance_ref{ConfigureVia};

    my @config_statements;

    if ( ref( $configure_via ) =~ /ARRAY/ ) {
        @config_statements = @{ $configure_via };
    }
    elsif ( not defined $configure_via ) {
        push @config_statements, 'Default';
    }
    else {
        push @config_statements, $configure_via;
    }

    foreach my $config ( @config_statements ) {
        my ( $method_name, @params ) = split /\s+/, $config;
        my $method                   = $dispatch{ $method_name };

        croak "Gantry::Conf ERROR: No such ConfigureVia method: $method_name\n"
                unless $method;

        $self->$method( $instance, $instance_ref, @params );
    }

    Hash::Merge::set_behavior( 'LEFT_PRECEDENT' ); 
    Hash::Merge::set_clone_behavior(0);

    # Merge in our global configs if we have any 
    if( $main_config{'global'} ) { 
        $$self{__global__} = $main_config{'global'};  

        $$self{__config__} = merge( $$self{__config__}, $$self{__global__} ); 

    }

    # Merge in any shared configs if any 
    my $shares = $$instance_ref{'use'}; 
    if( $shares and !ref($shares) ) { 

        $$self{__config__}
                = merge( $$self{__config__}, $main_config{'shared'}{$shares} ); 

    }
    elsif( $shares and ref($shares) eq 'ARRAY' ) { 
        foreach my $s ( @{ $shares } ) { 

            $$self{__config__} = merge( $$self{__config__}, 
                                        $main_config{'shared'}{$s} ); 

        }
    }

    # deal with location promotion
    if ( defined $location ) {
        my $locations     = delete $$self{__config__}{GantryLocation};
        my @path          = split( '/', $location );
        
        my @check_paths;
        
        while ( @path ) {
            my $path = join( '/', @path );
            push( @check_paths, $path );
            pop( @path );
        }

        foreach my $path ( reverse( @check_paths ) ) {
        
            my $location_hash = $$locations{$path};
            
            if ( defined $location_hash ) {
                
                $$self{__config__} = merge( 
                    $location_hash, 
                    $$self{__config__} 
                );
            }
        
            
        }

        #my $location_hash = $$locations{$location};   
        #if ( defined $location_hash ) {
        #    warn( "defined!2 $location" );
        #    $$self{__config__} = merge( 
        #        $location_hash, 
        #        $$self{__config__} 
        #    );
        #}
        
    }

} # END _load_configuration 

#------------------------------------------------
# _check_file( $file, readonly )
#------------------------------------------------
# This makes sure we can find, read, and write
# a particular file.  If readonly is passed to
# it then we only check to ensure we can read it
#------------------------------------------------
sub _check_file { 
    my $self        =   shift; 
    my $file        =   shift; 
    my $ro          =   shift || 0; 

    # Check for existance 
    if( ! -e $file ) { 
        croak "Gantry::Conf ERROR - Configuration file '$file' does not exist";
    }

    # Check for readability 
    if( ! -r $file ) { 
        croak "Gantry::Conf ERROR - Unable to read configuration file '$file' ".
              "check the file permissions"; 
    }

    # Check for write access if we are supposed to 
    if( not $ro and ( !-w $file ) ) { 
        croak "Gantry::Conf ERROR - Unable to write file '$file'. Check the ".
              " file permissions";
    }

    # Return true 
    return( 1 ); 

} # END _check_file 

#------------------------------------------------
# _configure_set_var 
#------------------------------------------------
# Load the configuration from the setvar 
# provider 
#------------------------------------------------
sub _configure_set_var { 
    my $self            =   shift; 
    my $instance        =   shift; 
    my $instance_ref    =   shift; 

    # Populate our configuration via the provider
    my $backend = 'Gantry::Conf::Provider::PerlSetVar';
    eval "require $backend"; 

    if( $@ ) { 
        croak "Unable to load '$backend': $!"; 
    }

    # Populate the configuration
    $$self{__config__} = 
            Gantry::Conf::Provider::PerlSetVar->config( $instance, 
                                                        $instance_ref ); 

    # Return true 
    return( 1 ); 

} # END _configure_set_var 

#------------------------------------------------
# _configure_parambuilder
#------------------------------------------------
sub _configure_parambuilder { 
    my $self            =   shift; 
    my $instance        =   shift; 
    my $instance_ref    =   shift; 
    my $provider        =   shift;
    my @files           =   @_;

} # END _configure_parambuilder 

#------------------------------------------------
# _configure_flat_file
#------------------------------------------------
# Use the indicated provider to load the 
# configuration from a flat file 
#------------------------------------------------
sub _configure_flat_file { 
    my $self            =   shift; 
    my $instance        =   shift; 
    my $instance_ref    =   shift; 
    my $provider        =   shift;
    my @files           =   @_;

    # Populate our configuration via the provider
    my $backend = 'Gantry::Conf::Provider::FlatFile::' . $provider; 
    eval "require $backend"; 

    if( $@ ) { 
        croak "Unable to require '$backend': $!"; 
    }

    Hash::Merge::set_behavior( 'LEFT_PRECEDENT' ); 
    Hash::Merge::set_clone_behavior(0);

    $$self{__config__} ||= {};
    foreach my $file_path ( @files ) {

        eval { 
            my $config_from_file = $backend->config( $file_path ); 
            $$self{__config__} = merge( $$self{__config__}, $config_from_file );
        };

        if( $@ ) { 
            croak 'Unable to load configuration via '
                .   "Gantry::Conf::Provider::FlatFile::$provider: $@ $!"; 
        }
    }

    # Return true 
    return( 1 ); 

} # END _configure_flat_file 

#------------------------------------------------
# _configure_sql 
#------------------------------------------------
sub _configure_sql { 
    my $self            =   shift; 
    my $instance        =   shift; 
    my $instance_ref    =   shift; 
    my $provider        =   shift;
    my @parameters      =   @_;

} # END _configure_sql 

#------------------------------------------------
# _configure_http
#------------------------------------------------
sub _configure_http { 
    my $self            =   shift; 
    my $instance        =   shift; 
    my $instance_ref    =   shift; 
    my $provider        =   shift;
    my @urls            =   @_;

    # Populate our configuration via the provider
    my $backend = 'Gantry::Conf::Provider::HTTP::' . $provider; 
    eval "require $backend"; 

    if( $@ ) { 
        croak "Unable to require '$backend': $@ $!"; 
    }

    Hash::Merge::set_behavior( 'LEFT_PRECEDENT' ); 
    Hash::Merge::set_clone_behavior(0);

    $$self{__config__} ||= {};

    foreach my $url ( @urls ) {

        eval { 
            my $config_from_web = $backend->config( $url ); 
            $$self{__config__} = merge( $$self{__config__}, $config_from_web );
        };

        if( $@ ) { 
            croak 'Unable to load configuration via '
                .   "Gantry::Conf::Provider::HTTP::$provider: $@ $!"; 
        }
    }

    return 1;

} # END _configure_http 

#------------------------------------------------
# _configure_main_conf 
#------------------------------------------------
# If the user didn't specify a ConfigureViaXXXX
# option then assume they want to configure in
# the main /etc/gantry.conf 
#------------------------------------------------
sub _configure_main_conf { 
    my $self            =   shift; 
    my $instance        =   shift; 
    my $instance_ref    =   shift; 
    my $provider        =   shift;
    my @files           =   @_;

    # Set hash merging precedence 
    Hash::Merge::set_behavior( 'LEFT_PRECEDENT' ); 
    Hash::Merge::set_clone_behavior(0);

    # Make sure we have a configuration already 
    $$self{__config__} ||= {};

    # Make a copy of our instance ref, skipping any 'use' methods
    my %temp_instance; 
    foreach my $key ( keys( %{ $instance_ref } ) ) { 
        next if $key eq 'use'; 
        $temp_instance{$key} = $$instance_ref{$key}; 
    }

    $$self{__config__} = merge( $$self{__config__}, \%temp_instance );

    # Return true 
    return( 1 ); 

} # END _configure_main_conf 

1;
__END__

=head1 NAME

Gantry::Conf - Gantry's Flexible Configuration System 

=head1 SYNOPSIS

  use Gantry::Conf; 

  # Retrieve a simple instance 
  my $conf = Gantry::Conf->retrieve( { instance => 'foo' } );

  # Retrieve an instance from an alternate configuration file
  # other than /etc/gantry.conf 
  my $conf2 = Gantry::Conf->retrieve({ 
          instance    => 'special', 
          config_file => '/etc/special.conf' 
  });

=head1 DESCRIPTION

Gantry::Conf is a configuration abstraction interface. While a part of the
Gantry Framework, it can be used alone, as it does not require any other
portions of Gantry. 

It is used to allow an application to bootstrap it's own configuration with
very little information. In most cases, the only information that an 
application needs to know in order to bootstrap itself is the name of 
its instance.  This instance name could be hard coded into the application,
but we strongly recommend using something more flexible.  

If you are new to Gantry::Conf see the C<Gantry::Conf::Tutorial> and the
C<Gantry::Conf::FAQ> for more information. 

=head1 METHODS

=over 4

=item new

This constructor is for internal use.  Call retrieve instead.

=item retrieve( $options_hash )

The retrieve method is the only method your application should call. It 
takes a hash of arguments.  All other methods defined in this module are
considered internal and their interfaces may change at any time, you
have been warned. The possible arguments are: 

=over 4

=item instance => 'foo' 

This is the unique name of the "instance" of this application.  This is
typically the only option given to retrieve() and is what is used to
bootstrap the rest of the configuration process.  This "instance" name
must match an entry in the configuration file. 

=item config_file => '/path/to/file.conf' 

By default Gantry::Conf looks at the file /etc/gantry.conf for its 
bootstrapping information.  This option allows you to override this default
behavior and have the system reference any file you desire.  Note the file
still must conform to the syntax of the main gantry.conf. 

=back 

=back 

=head1 SEE ALSO

Gantry(3), Gantry::Conf::Tutorial(3), Ganty::Conf::FAQ(3)

=head1 LIMITATIONS

Currently this system only works on Unix-like systems. 

=head1 AUTHOR

Frank Wiles <frank@revsys.com> 

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Frank Wiles. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

