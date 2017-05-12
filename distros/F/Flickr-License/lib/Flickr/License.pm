package Flickr::License;

use Carp;
use Flickr::License::Helper;
use strict;

=head1 NAME

Flickr::License - Represents the license of a photo from Flickr

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

        my $license=Flickr::License->new({api_key=>$APIKEY, id=>$license_number});
        if ($license->valid) {
            my $license_name = $license->name;
            my $license_url = $license->url;
        }

=head1 DESCRIPTION

This class retrieves data about the currently available Flickr photo licenses and returns the details that Flickr does based on the license number passed in.

The license number can be obtained easily from the Flickr::Photo object using the ->license() call.

If the license number isn't recognised in the data structure that Flickr returns then the "valid" property of the class is set to 0 and the name is set to "Invalid License"

Behind the scenes it uses a singleton that holds the necessary license date, only refreshing itself if it thinks it needs to.

=head1 METHODS

=head2 new

Sets up the license object.

my $license=Flickr::License->new({api_key => $APIKEY,
                                    id => $license_id});
                                    
id is optional and can be set using the ->id() setter/getter -> details of the license are only filled in once id is set.

=cut

sub new {
    my $class = shift;
    my $params = shift;

    if (!exists $params->{api_key}) {
        croak("Can't create a license without an Flick API key")
    }

    my $me = { api_key => $params->{api_key} };
        
    my $self  = bless $me, $class;

    # init the license helper
    my $factory=Flickr::License::Helper->instance($self->{api_key});

    if (exists $params->{id}) {
        $self->{id}=$params->{id};
        $self->_init;
    }

    return $self;
}

#_init
#Function to grab the license information from the Flickr::License::Helper object for this object.
#Will croak if the license id is not set. That shouldn't happen as it is only called when the id is set.

sub _init {
    my $self=shift;

    if (!exists $self->{id}) {
        croak "Cannot get license information without a license id";
    }

    my $number=$self->{id};

    my $factory=Flickr::License::Helper->instance();

    my $licenses=$factory->licenses;
    if (exists $licenses->{$number}) {
        $self->{name}=$licenses->{$number}->{name};
        $self->{url}=$licenses->{$number}->{url};
        $self->{valid}=1;
    } else {
        $self->{name}="Invalid license";        
        $self->{url}="";
        $self->{valid}=0;
    }

}

=head2 id

my $id = $license->id;
my $different_id = $license->id($a_different_id);

Returns the id. Also sets the id if an argument is passed in - it will always return the new id.

Will also populate the object with license information.

=cut

sub id {
    my $self=shift;
    my $num=shift;
    
    if (defined $num) {
        $self->{id}=$num;
        $self->_init;
    }
    
    return $self->{id};
}

=head2 name

Returns the license name

=cut

sub name {
    my $self=shift;
    return $self->{name};
}

=head2 url

Returns the license url

=cut

sub url {
    my $self=shift;
    return $self->{url};
}

=head2 valid

Returns whether the license id was valid. 0=false, 1=true.

=cut

sub valid {
    my $self=shift;
    return $self->{valid};
}

=head1 AUTHOR

Billy Abbott, C<< <billy@cowfish.org.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Billy Abbott, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

<http://www.flickr.com/>, Flickr::API, Flickr::Photo

=cut

1;
