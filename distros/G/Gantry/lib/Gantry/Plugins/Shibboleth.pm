package Gantry::Plugins::Shibboleth;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw( 
    auth_user_row 
    auth_user_groups
);

my %registered_callbacks;

#-----------------------------------------------------------
# $class->get_callbacks( $namespace )
#-----------------------------------------------------------
sub get_callbacks {
    my ( $class, $namespace ) = @_;

    return if ( $registered_callbacks{ $namespace }++ );

    return (
        { phase => 'init', callback => \&initialize },
    );
}

#-----------------------------------------------------------
# initialize
#-----------------------------------------------------------
sub initialize {
    my ( $gobj ) = @_;
    my $shib_attributes = $gobj->fish_config( 'shib_attributes' );
    my $shib_group_attribute = $gobj->fish_config( 'shib_group_attribute' );

    if ($shib_attributes) {
        my $attributes;
        my $obj;
        
        # Get the list of shibboleth attributes this application cares about.
        foreach my $attr ( split /,/o, $shib_attributes ) {
            $attributes->{$attr} = $ENV{$attr};
        }

        # Create AuthUserObject containing the attributes and save it
        # as the auth_user_row.
        $gobj->auth_user_row( Gantry::Plugins::Shibboleth::AuthUserObject->new( $attributes ) );
    }
    
    # If a group attribute was specified then load the group(s) from that attribute.
    if ( $shib_group_attribute ) {
        my $shib_groups = $ENV{$shib_group_attribute};
        my $groups;
        
        foreach my $shib_group ( split /\;/o, $shib_groups ) {
            $groups->{$shib_group} = 1;
        }
        
        $gobj->auth_user_groups( $groups );
    }
}

#-------------------------------------------------
# $self->auth_user_row
#-------------------------------------------------
sub auth_user_row {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_USER_ROW__} = $p if defined $p;
    return( $$self{__AUTH_USER_ROW__} ); 
    
} # end auth_user_row

#-------------------------------------------------
# $self->auth_user_groups
#-------------------------------------------------
sub auth_user_groups {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_USER_GROUPS__} = $p if defined $p;
    return( $$self{__AUTH_USER_GROUPS__} ); 
    
} # end auth_user_groups

package Gantry::Plugins::Shibboleth::AuthUserObject;

sub new {
    my( $class, $methods ) = @_;

    my $self = {};
    foreach my $method ( keys %$methods ) {
        
        Sub::Install::reinstall_sub({
            code => sub { return $methods->{$method} },
            into => __PACKAGE__,
            as   => $method
        }); 
    }

    bless( $self, $class );        
    return $self;    
}

1;


=head1 NAME

Gantry::Plugins::Shibboleth - Plugin for shibboleth based authentication

=head1 SYNOPSIS

Plugin must be included in the Applications use statment.

    <Perl>
        use MyApp qw{
                -Engine=CGI
                -TemplateEngine=TT
                -PluginNamespace=your_module_name
                Shibboleth
        };
    </Perl>

Bigtop:

    config {
        engine MP20;
        template_engine TT;
        plugins Shibboleth;
        ...

There are two config options.

shib_attributes         - Comma separated list of attributes that should be pulled from ENV.
shib_group_attribute    - Shibboleth attribute to use as the group membership.

=head1 DESCRIPTION

This plugin mixes in auth_user_row and auth_user_groups methods that get their
values from shibboleth attributes. auth_user_row is an object with accessor
methods for each of the shibboleth attributes. auth_user_groups returns a hash
of groups that are taken from the attribute specified in the configuration file
as the shib_group_attribute.

=head1 CONFIGURATION

The plugin needs to be specified in your application use statement. The only
required config option is shib_attributes which is a comma separated list of
attributes you want to be loaded into the auth_user_row. You can also specify
a shib_group_attribute which will be used to populate the hash returned
by the auth_user_groups method.

=head1 CONFIG OPTIONS

    shib_attributes         - Comma separated list of attributes that should be pulled from ENV.
    shib_group_attribute    - Shibboleth attribute to use as the group membership.

=head1 METHODS

=over 4

=item get_callbacks

Registers the initialize function as a init level callback.

=item auth_user_row

This is mixed into the gantry object and can be called retrieve the user
row which is an object with accessor methods for each of the specified
shibboleth attributes.

=item auth_user_groups

This is mixed into the gantry object and can be called to retrieve the
defined groups for the authed user.

=item initialize

This method is called on each request to load the specified shibboleth attributes.

=back

=head1 SEE ALSO

    Gantry

=head1 AUTHOR

John Weigel <jweigel@sunflowerbroadband.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 The World Company

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
