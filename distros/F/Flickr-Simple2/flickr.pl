#!/usr/bin/perl

use strict;
use warnings;

use Config::Simple;
use Flickr::Simple2;

my $cfg = new Config::Simple('config.ini');

my $flickr = Flickr::Simple2->new({
        api_key => $cfg->param('Flickr.API_KEY'),
        api_secret => $cfg->param('Flickr.API_SHARED_SECRET'),
        auth_token => $cfg->param('Flickr.auth_token') ? $cfg->param('Flickr.auth_token') : undef
    });

unless ( $cfg->param('Flickr.auth_token') && (my $auth = $flickr->check_auth_token()) ) {
    my $frob = $flickr->get_auth_frob();
    my $auth_url = $flickr->get_auth_url($frob, 'read');
    print "$auth_url\n";
    
    if ($auth_url) {
        sleep 60;
        my $auth_token = $flickr->get_auth_token($frob);
        $cfg->param('Flickr.auth_token', $auth_token);
        $cfg->write();  
    }
}

#my $user = $flickr->get_user_byEmail('jason_froebe@yahoo.com');
#my $user = $flickr->get_user_byUserName('jason_froebe');
my $user = $flickr->get_user_byURL('http://www.flickr.com/photos/jfroebe/3214186886/');
my $public_photos = $flickr->get_public_photos($user->{nsid}, { per_page => 3 });

foreach my $photo_id (keys %{ $public_photos->{photo} }) {
    printf "%s\n", $public_photos->{photo}->{$photo_id}->{secret};
    my $photo_detail = $flickr->get_photo_detail($photo_id, $public_photos->{photo}->{$photo_id}->{secret});
    use Data::Dumper;
    print Dumper($photo_detail);
    exit;
}