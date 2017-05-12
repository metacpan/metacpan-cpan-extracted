package Flickr::License::Helper;
use Class::Singleton;
use Flickr::API;
use Flickr::API::Utils;
use Carp;
use strict;

use vars qw(@ISA);
@ISA = qw(Class::Singleton);

=head1 NAME

Flickr::License::Helper - Helper class to grab details of the currently supported licenses on Flickr

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

       my $helper = Flickr::License::Helper->get_instance($APIKEY);
       
       my $license_name = $helper->licenses->{$license_id}{name};
       my $license_url = $helper->licenses->{}$license_id}{url};

=head1 DESCRIPTION

The class is a singleton that caches the data returned by the flickr.photo.getLicenses api call in a simple hash.

It only grabs the data when the API key is set or changed, or if the refresh function is explicitly called.

=head1 METHODS

=cut

#_new_instance
#Returns a new instance of the Helper.
#It is called by the Class::Singleton method ->instance() if the class is not initialised.

sub _new_instance {
    my $class = shift;
    my $api_key = shift;

    my $me = { utils => Flickr::API::Utils->new() };    
    
    my $self  = bless $me, $class;

    if (defined $api_key) {
        $self->api_key($api_key);
    }

    return $self;
}

=head2 api_key

Returns the current api_key. If an argument is passed in that is set to be the current api_key.

If the key has changed then the license data is refreshed from flickr

=cut

sub api_key {
    my $self=shift;
    my $key=shift;

    
    if (defined $key &&
        (!exists $self->{api_key} || !defined $self->{api_key} || $self->{api_key} ne $key))
    {
        $self->{api_key}=$key;
        $self->refresh();
    }
    
    return $self->{api_key};
}

=head2 refresh

Refreshes the internal cache from flickr

=cut

sub refresh {

    my $self=shift;

    # no license key means no hash
    if ($self->{api_key} eq '') {
        croak "No flickr API key defined, can't get license info";
    }

    my $api=new Flickr::API({key => $self->{api_key}});
    my $response=$api->execute_method('flickr.photos.licenses.getInfo');

# License info as of 20070711
#    my $xml=<<END
#<licenses>
#	<license id="4" name="Attribution License"
#		url="http://creativecommons.org/licenses/by/2.0/" /> 
#	<license id="6" name="Attribution-NoDerivs License"
#		url="http://creativecommons.org/licenses/by-nd/2.0/" /> 
#	<license id="3" name="Attribution-NonCommercial-NoDerivs License"
#		url="http://creativecommons.org/licenses/by-nc-nd/2.0/" /> 
#	<license id="2" name="Attribution-NonCommercial License"
#		url="http://creativecommons.org/licenses/by-nc/2.0/" /> 
#	<license id="1" name="Attribution-NonCommercial-ShareAlike License"
#		url="http://creativecommons.org/licenses/by-nc-sa/2.0/" /> 
#	<license id="5" name="Attribution-ShareAlike License"
#		url="http://creativecommons.org/licenses/by-sa/2.0/" /> 
#</licenses>
#END
#    ;

    my $result={};
    $self->{utils}->test_return($response,$result);
    if ($result->{success}) {
        my $xml=$response;#->{_content};
        $self->{licenses} = $self->_parse_licenses($xml);
    } else {
        croak "Failed to get license data: $result->{error_message} ($result->{error_code})";
    }
}

# _parse_licenses
# parses the license data returned by flickr into the internal cache

sub _parse_licenses {

    my $self=shift;
    my $xml=shift;

    my $ret = {};

    foreach my $node (@{$xml->{tree}{children}}) {
        if ($node->{type} eq 'tag' and $node->{name} eq 'licenses') {
            foreach my $license (@{$node->{children}}) {
                if ($license->{type} eq 'tag' and $license->{name} eq 'license') {
                    $ret->{$license->{attributes}{id}}{name}=$license->{attributes}{name};
                    $ret->{$license->{attributes}{id}}{url}=$license->{attributes}{url};
                }
            }
        }
    }

    return $ret;

}

=head2 licenses

Returns a handle to the internal cache of licenses. The structure should look something like this:

    {
        '6' => {
                'url' => 'http://creativecommons.org/licenses/by-nd/2.0/',
                'name' => 'Attribution-NoDerivs License'
               },
        '1' => {
                'url' => 'http://creativecommons.org/licenses/by-nc-sa/2.0/',
                'name' => 'Attribution-NonCommercial-ShareAlike License'
               },
        '4' => {
                'url' => 'http://creativecommons.org/licenses/by/2.0/',
                'name' => 'Attribution License'
               },
        '3' => {
                'url' => 'http://creativecommons.org/licenses/by-nc-nd/2.0/',
                'name' => 'Attribution-NonCommercial-NoDerivs License'
               },
        '0' => {
                'url' => '',
                'name' => 'All Rights Reserved'
               },
        '2' => {
                'url' => 'http://creativecommons.org/licenses/by-nc/2.0/',
                'name' => 'Attribution-NonCommercial License'
               },
        '5' => {
                'url' => 'http://creativecommons.org/licenses/by-sa/2.0/',
                'name' => 'Attribution-ShareAlike License'
                }
    }

=cut

sub licenses {
    my $self=shift;
    return $self->{licenses};
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
