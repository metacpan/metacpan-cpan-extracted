use strict;
package DigitalOcean;
use Mouse; 

use DigitalOcean::Response;
use DigitalOcean::Droplet;
use DigitalOcean::Meta;
use DigitalOcean::Links;
use DigitalOcean::Collection;
use DigitalOcean::Account;
use DigitalOcean::Action;
use DigitalOcean::Domain;
use DigitalOcean::Droplet::Upgrade;
use DigitalOcean::SSH::Key;

#for requesting
use LWP::UserAgent;
use LWP::Protocol::https;

#for dealing with JSON
use JSON::XS;

#for printing pretty deaths
use Data::Dumper qw//;

#DigitalOcean packages
use DigitalOcean::Error;

#ABSTRACT: An OO interface to the Digital Ocean API (v2).

has oauth_token => ( 
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has ua => ( 
    is  => 'ro', 
    isa => 'LWP::UserAgent', 
    required    => 0, 
    default => sub { LWP::UserAgent->new },
);

has api => (
    is => 'ro',
    isa => 'Str',
    default => 'https://api.digitalocean.com/v2/',
    required => 0,
);

has 'time_between_requests' => (
        is => 'rw',
        isa => 'Int',
        default => 2,
        required => 0,
);

has 'wait_on_actions' => (
        is => 'rw',
        isa => 'Bool',
        default => undef,
        required => 0,
);


has ratelimit_limit => (
    is => 'rw',
);


has ratelimit_remaining => (
    is => 'rw',
);


has ratelimit_reset => (
    is => 'rw',
);

#define constants for HTTP request types
use constant {
    GET => 'GET',
    DELETE => 'DELETE',
    PUT => 'PUT',
    POST => 'POST',
    HEAD => 'HEAD',
};


has die_pretty => ( 
    is => 'rw',
    isa => 'Bool',
    default => 1, 
);


has last_response => (
    is => 'rw',
    isa => 'Undef|DigitalOcean::Response',
    default => undef,
);


has per_page => (
    is => 'rw',
    isa =>'Undef|Int',
    default => undef,
);

sub _request { 
    my $self = shift;
    my (%args) = @_;
    my ($req_method, $path, $params, $req_body_hash, $type) = ($args{req_method}, $args{path}, $args{params}, $args{req_body_hash}, $args{type});
    
    #create request
    my $uri = URI->new($self->api . $path);

    #assign per_page if global value is set and one was not passed in
    if(not $params->{per_page} and $self->per_page) { 
        $params->{per_page} = $self->per_page;
    }

    $uri->query_form($params);

    my $req = HTTP::Request->new(
        $req_method,
        $uri,
    );

    #add authentication
    $req->header(Authorization => 'Bearer ' . $self->oauth_token);

    my $wait_on_action;

    #set body content
    if($req_body_hash) {
        #get wait on action out if it was passed in
        $wait_on_action = delete $req_body_hash->{wait_on_action};

        #set json header
        $req->header('Content-Type' => 'application/json');

        #put json in body
        my $json_coder = JSON::XS->new->ascii->allow_nonref;
        my $req_body = $json_coder->encode($req_body_hash);
        $req->content($req_body);
    }

    my $response = $self->ua->request($req);
    my $json;
    if($response->content) {
        $json = JSON::XS->new->utf8->decode($response->content);

        #die with DigitalOcean::Error
        if($response->code < 200 or $response->code >= 300) {
            my $do_error = DigitalOcean::Error->new(
                id => $json->{id},
                message => $json->{message},
                status_code => $response->code,
                status_message => $response->message,
                status_line => $response->status_line,
            );

            die $self->die_pretty ? Data::Dumper->Dump([$do_error, $self]) : $do_error;
        }

    }

    my $do_response = DigitalOcean::Response->new(
        json => $json,
        status_code => $response->code,
        status_message => $response->message,
        status_line => $response->status_line,
    );

    if($json and ref($json) eq 'HASH') {
        #add meta object if one was passed back
        $do_response->meta(DigitalOcean::Meta->new(%{$json->{meta}})) if $json->{meta};

        if($json->{links}) {
            #add links object if one was passed back
            $do_response->links(DigitalOcean::Links->new(%{$json->{links}}));

            #if actions array is present and we are supposed to wait on events, then wait!
            if($json->{links}->{actions} and ($self->wait_on_actions or $wait_on_action)) { 
                #wait on each returned action that occurred from the API call
                for my $act_temp (@{$json->{links}->{actions}}) { 
                    my $action = $self->action($act_temp->{id});

                    #wait on action
                    $action->wait; 
                } 
            }
        }
    }

    $self->last_response($do_response);

    #parse ratelimit headers
    $self->ratelimit_limit($response->header('RateLimit-Limit'));
    $self->ratelimit_remaining($response->header('RateLimit-Remaining'));
    $self->ratelimit_reset($response->header('RateLimit-Reset'));

    return $do_response;
}

sub _GET { 
    my $self = shift;
    my (%args) = @_;
    $args{req_method} = GET;

    return $self->_request(%args);
}

sub _POST { 
    my $self = shift;
    my (%args) = @_;
    $args{req_method} = POST;

    return $self->_request(%args);
}

sub _DELETE { 
    my $self = shift;
    my (%args) = @_;
    $args{req_method} = DELETE;

    return $self->_request(%args);
}

sub _PUT { 
    my $self = shift;
    my (%args) = @_;
    $args{req_method} = PUT;

    return $self->_request(%args);
}

sub _decode { 
    my ($self, $type, $json, $key) = @_;
    my $attrs = $key ? $json->{$key} : $json;
    $attrs->{DigitalOcean} = $self;
    return $type->new($attrs);
}

sub _decode_many { 
    my ($self, $type, $arr) = @_;
    [map { $self->_decode($type, $_) } @{$arr}];
}


sub get_user_information {
    my ($self) = @_;

    my $do_response = $self->_GET(path => "account");
    return $self->_decode('DigitalOcean::Account', $do_response->json, 'account');
}

sub _get_collection { 
    my ($self, $path, $type_name, $json_key, $params, $init_objects) = @_;

    $init_objects = [] unless $init_objects;

    my $do_response = $self->_GET(path => $path, params => $params);

    return DigitalOcean::Collection->new (
        DigitalOcean => $self,
        type_name => $type_name,
        json_key => $json_key,
        params => $params,
        response => $do_response,
        init_objects => $init_objects,
    );
}

sub _get_object { 
    my ($self, $path, $type_name, $json_key) = @_;

    my $do_response = $self->_GET(path => $path);
    return $self->_decode($type_name, $do_response->json, $json_key);
}

sub _get_array { 
    my ($self, $path, $type_name, $json_key) = @_;

    my $do_response = $self->_GET(path => $path);

    my $arr;
    if($json_key) { 
        $arr = $do_response->json->{$json_key};
    }
    else { 
        $arr = $do_response->json;
    }

    return $self->_decode_many($type_name, $arr);
}

sub _put_object { 
    my ($self, $path, $type_name, $json_key, $req_body_hash) = @_;

    my $do_response = $self->_PUT(path => $path, req_body_hash => $req_body_hash);
    return $self->_decode($type_name, $do_response->json, $json_key);
}

sub _post_object { 
    my ($self, $path, $type_name, $json_key, $req_body_hash) = @_;

    my $do_response = $self->_POST(path => $path, req_body_hash => $req_body_hash);
    return $self->_decode($type_name, $do_response->json, $json_key);
}

sub _create { 
    my ($self, $path, $type_name, $json_key, $req_body_hash) = @_;

    my $do_response = $self->_POST(path => $path, req_body_hash => $req_body_hash);
    return $self->_decode($type_name, $do_response->json, $json_key);
}

sub _delete { 
    my $self = shift;
    my (%args) = @_;
    my $do_response = $self->_DELETE(%args);

    return $do_response->status_code == 204;
}

sub _action { 
    my $self = shift;
    my (%args) = @_;

    #don't delete, because _request might need to wait on event
    my $wait_on_action = $args{req_body_hash}->{wait_on_action};

    my $do_response = $self->_POST(%args);

    my $action = $self->_decode('DigitalOcean::Action', $do_response->json, 'action');

    $action->wait if $wait_on_action or $self->wait_on_actions;

    return $action;
}


sub actions {
    my ($self, $per_page) = @_;
    my $init_arr = [['DigitalOcean', $self]];
    return $self->_get_collection('actions', 'DigitalOcean::Action', 'actions', {per_page => $per_page}, $init_arr);
}


sub action {
    my ($self, $id) = @_;

    return $self->_get_object("actions/$id", 'DigitalOcean::Action', 'action');
}


sub domains {
    my ($self, $per_page) = @_;
    my $init_arr = [['DigitalOcean', $self]];
    return $self->_get_collection('domains', 'DigitalOcean::Domain', 'domains', {per_page => $per_page}, $init_arr);
}

 
sub create_domain {
    my $self = shift;
    my %args = @_;

    my $domain = $self->_create('domains', 'DigitalOcean::Domain', 'domain', \%args);
    $domain->DigitalOcean($self);

    return $domain;
}


sub domain {
    my ($self, $id) = @_;

    my $domain = $self->_get_object("domains/$id", 'DigitalOcean::Domain', 'domain');
    $domain->DigitalOcean($self);

    return $domain;
}


sub create_droplet {
    my $self = shift;
    my %args = @_;

    my $droplet = $self->_create('droplets', 'DigitalOcean::Droplet', 'droplet', \%args);
    $droplet->DigitalOcean($self);

    return $droplet;
}


sub droplet {
    my ($self, $id) = @_;

    my $droplet = $self->_get_object("droplets/$id", 'DigitalOcean::Droplet', 'droplet');
    $droplet->image->DigitalOcean($self);

    return $droplet;
}


sub droplets {
    my ($self, $per_page) = @_;
    my $init_arr = [['DigitalOcean', $self]];
    return $self->_get_collection('droplets', 'DigitalOcean::Droplet', 'droplets', {per_page => $per_page}, $init_arr);
}


sub droplet_upgrades { 
    my ($self) = @_;

    return $self->_get_array('droplet_upgrades', 'DigitalOcean::Droplet::Upgrade');
}

sub _images { 
    my ($self, $params) = @_;
    my $init_arr = [['DigitalOcean', $self]];
    return $self->_get_collection('images', 'DigitalOcean::Image', 'images', $params, $init_arr);
}


sub images {
    my ($self, $per_page) = @_;
    return $self->_images({per_page => $per_page});
}


sub distribution_images {
    my ($self, $per_page) = @_;
    return $self->_images({per_page => $per_page, type => 'distribution'});
}


sub application_images {
    my ($self, $per_page) = @_;
    return $self->_images({per_page => $per_page, type => 'application'});
}


sub user_images {
    my ($self, $per_page) = @_;
    return $self->_images({per_page => $per_page, private => 'true'});
}


sub image {
    my ($self, $id_or_slug) = @_;

    my $image = $self->_get_object("images/$id_or_slug", 'DigitalOcean::Image', 'image');

    return $image;
}


sub ssh_keys {
    my ($self, $per_page) = @_;
    my $init_arr = [['DigitalOcean', $self]];
    return $self->_get_collection('account/keys', 'DigitalOcean::SSH::Key', 'ssh_keys', {per_page => $per_page}, $init_arr);
}

 
sub create_ssh_key {
    my $self = shift;
    my %args = @_;

    my $ssh_key = $self->_create('account/keys', 'DigitalOcean::SSH::Key', 'ssh_key', \%args);
    $ssh_key->DigitalOcean($self);

    return $ssh_key;
}


sub ssh_key {
    my ($self, $id_or_finger) = @_;

    my $ssh_key = $self->_get_object("account/keys/$id_or_finger", 'DigitalOcean::SSH::Key', 'ssh_key');

    return $ssh_key;
}


sub regions {
    my ($self, $per_page) = @_;
    return $self->_get_collection('regions', 'DigitalOcean::Region', 'regions', {per_page => $per_page});
}


sub sizes {
    my ($self, $per_page) = @_;
    return $self->_get_collection('sizes', 'DigitalOcean::Size', 'sizes', {per_page => $per_page});
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean - An OO interface to the Digital Ocean API (v2).

=head1 VERSION

version 0.17

=head1 METHODS

=head2 ratelimit_limit

Returns the number of requests that can be made per hour. See L<here|https://developers.digitalocean.com/documentation/v2/#rate-limit> for more details.

=head2 ratelimit_remaining

Returns the number of requests that remain before you hit your request limit. See L<here|https://developers.digitalocean.com/documentation/v2/#rate-limit> for more details.

=head2 ratelimit_reset

This returns the time when the oldest request will expire. The value is given in Unix epoch time. See L<here|https://developers.digitalocean.com/documentation/v2/#rate-limit> for more details.

=head2 die_pretty

This method controls how L<DigitalOcean> will die when it receives an error from the Digital Ocean API.
If it is set to 1, then L<DigitalOcean> will die with a string representation of a L<DigitalOcean::Error> object. 
This is useful for debugging and seeing immediately what caused the error. If it is set to undef, then L<DigitalOcean> 
will die with a L<DigitalOcean::Error> object instead of its string representation. This is useful if you want to 
handle the returned error programmatically. The default is 1.

    $do->die_pretty(undef); #when a Digital Ocean API error is received, will die with DigitalOcean::Error object

    $do->die_pretty(1); #when a Digital Ocean API error is received, will die with the string representation of the DigitalOcean::Error object

    my $droplets;
    try { 
        $droplets = $do->droplets;
    }
    catch { 
        my $do_error = $_;

        if($do_error->status_code >= 400 and $do_error->status_code < 500) { 
            print "probably an issue with the request...\n";
        }
        elsif($do_error->status_code >= 500) {
            print "probably an issue with the Digital Ocean API...\n"; 
        }
        if($do_error->status_code >= 200 and $do_error->status_code < 300) { 
            print "this should not have been an error...\n";
        }
        else { 
            print "not sure what the error means...\n";
        }

        print "id: " . $do_error->id . "\n";
        print "message: " . $do_error->message . "\n";
        print "status_code: " . $do_error->status_code . "\n";
        print "status_message: " . $do_error->status_message . "\n";
        print "status_line: " . $do_error->status_line . "\n";
    }

=head2 last_response

This method returns the last L<DigitalOcean::Response> from the most recent API request. This contains useful information about
the request, such as the L<DigitalOcean::Response's status_code|DigitalOcean::Response/"status_code"> or the L<DigitalOcean::Meta> object.
It returns undef if no API requests have been made yet. 

    my $last_response = $do->last_response;

    my $status_code = $do->status_code;
    print "Status code from last response $status_code\n";

    my $status_message = $do->status_message;
    print "Status message from last response $status_message\n";

    my $total = $do->meta->total;
    print "Total objects returned in last response $total\n";

=head2 per_page

This method can force pagination to a certain value instead of the default value of 25 when requesting collections.

    #now 2 items will be returned per page for collections
    $do->per_page(2);

The default is undef, which just means that the Digital Ocean API's default will be used.

=head2 get_user_information

Returns a L<DigitalOcean::Account> object.

    my $account = $do->get_user_information;

    print "Droplet limit: " . $account->droplet_limit . "\n";
    print "Email: " . $account->email . "\n";
    print "uuid: " . $account->uuid . "\n";
    print "Email Verified: " . $account->email_verified . "\n";

=head2 actions

This will return a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Action> objects of the actions collection. 

    my $actions_collection = $do->actions;
    my $obj;

    while($obj = $actions_collection->next) { 
        print $obj->id . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $actions_collection = $do->actions(2);
    my $obj;

    while($obj = $actions_collection->next) { 
        print $obj->id . "\n";
    }

=head2 action

This will retrieve an action by id and return a L<DigitalOcean::Action> object.

    my $action = $do->action(56789);

=head2 domains

This will return a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Domain> objects of the domains collection. 

    my $domains_collection = $do->domains;
    my $obj;

    while($obj = $domains_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $domains_collection = $do->domains(2);
    my $obj;

    while($obj = $domains_collection->next) { 
        print $obj->name . "\n";
    }

=head2 create_domain

This will create a new domain and return a L<DigitalOcean::Domain> object. The parameters are:

=over 4

=item

B<name> Required, String, The domain name to add to the DigitalOcean DNS management interface. The name must be unique in DigitalOcean's DNS system. The request will fail if the name has already been taken.

=item

B<ip_address> Required, String, This attribute contains the IP address you want the domain to point to.

=back

    my $domain = $do->create_domain(
        name => 'example.com',
        ip_address => '127.0.0.1',
    );

Keep in mind that, upon creation, the zone_file field will have a value of null until a zone file is generated and propagated through an automatic process on the DigitalOcean servers.

=head2 domain

This will retrieve a domain by name and return a L<DigitalOcean::Domain> object.

    my $domain = $do->domain('example.com');

=head2 create_droplet

This will create a new droplet and return a L<DigitalOcean::Droplet> object. The parameters are:

=over 4

=item

B<name> Required, String, The human-readable string you wish to use when displaying the Droplet name. The name, if set to a domain name managed in the DigitalOcean DNS management system, will configure a PTR record for the Droplet. The name set during creation will also determine the hostname for the Droplet in its internal configuration.

 =item 

B<region> Required, String, The unique slug identifier for the region that you wish to deploy in.

=item

B<size> Required, String, The unique slug identifier for the size that you wish to select for this Droplet.

=item

B<image> Required, number (if using an image ID), or String (if using a public image slug), The image ID of a public or private image, or the unique slug identifier for a public image. This image will be the base image for your Droplet.

=item

B<ssh_keys> Optional, Array Reference, An array reference containing the IDs or fingerprints of the SSH keys that you wish to embed in the Droplet's root account upon creation.

=item

B<backups> Optional, Boolean, A boolean indicating whether automated backups should be enabled for the Droplet. Automated backups can only be enabled when the Droplet is created.

=item

B<ipv6> Optional, Boolean, A boolean indicating whether IPv6 is enabled on the Droplet.

=item

B<private_networking> Optional, Boolean, A boolean indicating whether private networking is enabled for the Droplet. Private networking is currently only available in certain regions.

=item

B<user_data> Optional, String, A string of the desired User Data for the Droplet. User Data is currently only available in regions with metadata listed in their features.

=back

    my $new_droplet = $do->create_droplet(
        name => 'new_droplet',
        region => $region,
        size => $size,
        image => $image,
    );
 

    Even though this method does not return a L<DigitalOcean::Action>, it can still be used with L</wait_on_action> and L</wait_on_actions>.

=head2 droplet

This will retrieve a droplet by id and return a L<DigitalOcean::Droplet> object.

    my $droplet = $do->droplet(56789);

=head2 droplets

This will return a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Droplet> objects of the droplets collection. 

    my $droplets_collection = $do->droplets;
    my $obj;

    while($obj = $droplets_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $droplets_collection = $do->droplets(2);
    my $obj;

    while($obj = $droplets_collection->next) { 
        print $obj->name . "\n";
    }

=head2 droplet_upgrades

This method retrieves a list of droplets that are scheduled to be upgraded as L<DigitalOcean::Droplet::Upgrade> objects and returns them as an array reference.

    my $droplet_upgrades = $do->droplet_upgrades;

    for my $upgrade (@$droplet_upgrades) { 
        print "ID: " . $upgrade->droplet_id . "\n";
        print "Date of migration: " . $upgrade->date_of_migration . "\n";
        print "url " . $upgrade->url . "\n";
        print "\n";
    }

=head2 images

This will return a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Image> objects of the images collection. 

    my $images_collection = $do->images;
    my $obj;

    while($obj = $images_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $images_collection = $do->images(2);
    my $obj;

    while($obj = $images_collection->next) { 
        print $obj->name . "\n";
    }

=head2 distribution_images 

This method will retrieve only distribution images. It returns a L<DigitalOcean::Collection> of L<DigitalOcean::Image> objects.

    my $images_collection = $do->distribution_images;
    my $obj;

    while($obj = $images_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $images_collection = $do->distribution_images(2);
    my $obj;

    while($obj = $images_collection->next) { 
        print $obj->name . "\n";
    }

=head2 application_images 

This method will retrieve only application images. It returns a L<DigitalOcean::Collection> of L<DigitalOcean::Image> objects.

    my $images_collection = $do->application_images;
    my $obj;

    while($obj = $images_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $images_collection = $do->application_images(2);
    my $obj;

    while($obj = $images_collection->next) { 
        print $obj->name . "\n";
    }

=head2 user_images

This method will retrieve only your private images. It returns a L<DigitalOcean::Collection> of L<DigitalOcean::Image> objects.

    my $images_collection = $do->user_images;
    my $obj;

    while($obj = $images_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $images_collection = $do->user_images(2);
    my $obj;

    while($obj = $images_collection->next) { 
        print $obj->name . "\n";
    }

=head2 image

This will retrieve an image by id or by slug and return a L<DigitalOcean::Image> object.

    my $image = $do->image(11836690);

    #or

    my $image = $do->image('ubuntu-14-04-x64');

=head2 ssh_keys

This will return a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::SSH::Key> objects of the droplets collection. 

    my $keys_collection = $do->ssh_keys;
    my $obj;

    while($obj = $keys_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $keys_collection = $do->ssh_keys(2);
    my $obj;

    while($obj = $keys_collection->next) { 
        print $obj->name . "\n";
    }

=head2 create_ssh_key

This will create a new ssh key and add it to your account and return a L<DigitalOcean::SSH::Key> object. The parameters are:

=over 4

=item

B<name> Required, String, The name to give the new SSH key in your account.

=item

B<public_key> Required, String, A string containing the entire public key.

=back

    my $ssh_key = $do->create_ssh_key(
        name => 'new_ssh_key',
        public_key => $ssh_pub_key,
    );

=head2 ssh_key

This will retrieve an ssh key by id or by fingerprint and return a L<DigitalOcean::SSH::Key> object.

    my $ssh_key = $do->ssh_key(11836690);

    #or

    my $ssh_key = $do->ssh_key('7a:61:d4:1c:b3:b0:c6:0b:9e:e2:c9:ff:35:f0:a0:dd');

=head2 regions

This will return a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Region> objects of the regions collection. 

    my $regions_collection = $do->regions;
    my $obj;

    while($obj = $regions_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $regions_collection = $do->regions(2);
    my $obj;

    while($obj = $regions_collection->next) { 
        print $obj->name . "\n";
    }

=head2 sizes

This will return a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Size> objects of the sizes collection. 

    my $sizes_collection = $do->sizes;
    my $obj;

    while($obj = $sizes_collection->next) { 
        print $obj->slug . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L</per_page>, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $sizes_collection = $do->sizes(2);
    my $obj;

    while($obj = $sizes_collection->next) { 
        print $obj->slug . "\n";
    }

=head1 DOCUMENTATION NEEDS WORK

So I have updated the DigitalOcean module to be compatible with version 2. Unfortunately I have not had time to
finish writing the documentation or tests yet. However, I have chosen to release the module anyway since as of
November 1, 2015 API 1 will no longer work, which means that the older versions of this module will no longer work.
I will try to update with documentation and tests as soon as I can. Until then, if something is unclear you can
look at the code to help figure out how it works. You can also submit a L<pull request|https://github.com/srchulo/DigitalOcean/tree/v2>
if you'd like to help with the documentation.

=head1 WAITING ON ACTIONS

=head2 wait_on_actions

For some calls in Digital Ocean's API, you need to wait for one call to finish before you can
submit another request that depends on the first call. For instance, if you resize a droplet
and then want to take a snapshot of the droplet, you must wait until the action of resizing
the droplet is complete before you can take the snapshot of this droplet. If you set wait_on_actions
to 1, then L<DigitalOcean> will wait on every action until it is complete, so this way you do not have to worry 
about the synchronization of events or if you need to wait between two events. However,
turning wait_on_actions on for every action can also cause your script to run much slower if you do not need
to be waiting on every action.

You may wait on all events by passing in wait_on_actions when you create the L<DigitalOcean> object:

    my $do = DigitalOcean->new(oauth_token => $oauth_token, wait_on_actions => 1);

Or you can toggle it after you have created the L<DigitalOcean> object:

    $do->wait_on_actions(1);
    $do->wait_on_actions(undef);

The default for wait_on_actions is that it is set to undef and does not wait on actions.

=head2 wait_on_action

A more efficient solution is to only wait on indiviudal actions that you have to wait on. You can pass in the
wait_on_action flag to any subroutine that returns a L <DigitalOcean::Action> object (and also L</create_droplet>)
and L<DigitalOcean> will wait until that call is complete before returning.

    my $droplet = $do->create_droplet(
        name => 'new_droplet',
        size_id => $size_id,
        image_id => $image_id,
        region_id => $region_id,
        wait_on_event => 1,
    );
 
    $droplet->reboot(wait_on_event => 1);
    $droplet->snapshot(wait_on_event => 1);
 
    etc.

L<DigitalOcean> uses L<DigitalOcean::Event's wait|DigitalOcean::Event/"wait"> subroutine to wait on events.

=head2 time_between_requests

L<DigitalOcean> uses L<DigitalOcean::Event's wait|DigitalOcean::Event/"wait"> subroutine to wait on events. It does
this by making requests to Digital Ocean until the L<event|DigitalOcean::Event> is complete. You can use time_between_requests
to determine how long L<DigitalOcean> waits between requests before making another request to Digital Ocean to see if an event is
done. You can use it like so:

    $do->time_between_requests(1);

or

    my $do = DigitalOcean->new(client_id=> $client_id, api_key => $api_key, time_between_requests => 1);

An integer value must be passed in. The default is 2.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
