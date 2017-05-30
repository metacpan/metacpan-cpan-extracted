package TestServer::Users;
use base qw( TestServer::Plugin );
use strict;
use warnings;
use 5.010;

use JSON;

sub import {
    my $class = __PACKAGE__;
    $class->register_dispatch(
        '/rest/api/latest/myself' =>
            sub { $class->myself(@_) },
    );
}

sub myself {
    my ( $class, $server, $cgi ) = @_;
    return $class->response($server, $class->user($server, $cgi, 'packy'));
}

sub user {
    my ( $class, $server, $cgi, $key ) = @_;

    my ($user) = grep {
        $_->{key} eq $key
    } @{ $class->users($server, $cgi) };

    return $user;
}

sub minuser {
    my ( $class, $server, $cgi, $key ) = @_;

    my $user = $class->user($server, $cgi, $key);

    my $min = {};

    foreach my $k ( qw/ active avatarUrls displayName key name self / ) {
        $min->{$k} = $user->{$k};
    }

    return $min;
}


sub users {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    my $grav_packy = 'http://www.gravatar.com/avatar/'
        . 'eec44a1b7d907db7922446f61898bffc?d=mm';

    my $grav_nobody = 'http://www.gravatar.com/avatar/'
        . '54c28ffbbe4efe304714c42dd5d713ce?d=mm';

    return [
        {
            active => JSON::PP::true,
            applicationRoles => {
                items => [],
                size => 1
            },
            avatarUrls => {
                "16x16" => "$grav_packy&s=16",
                "24x24" => "$grav_packy&s=24",
                "32x32" => "$grav_packy&s=32",
                "48x48" => "$grav_packy&s=48"
            },
            displayName => "Packy Anderson",
            emailAddress => 'packy\@cpan.org',
            expand => "groups,applicationRoles",
            groups => {
                items => [],
                size => 2
            },
            key => "packy",
            locale => "en_US",
            name => "packy",
            self => "$url/rest/api/2/user?username=packy",
            timeZone => "America/New_York"
        },
        {
            active => JSON::PP::true,
            applicationRoles => {
                items => [],
                size => 1
            },
            avatarUrls => {
                "16x16" => "$grav_nobody&s=16",
                "24x24" => "$grav_nobody&s=24",
                "32x32" => "$grav_nobody&s=32",
                "48x48" => "$grav_nobody&s=48"
            },
            displayName => "Kay Koch",
            emailAddress => 'packy\@cpan.org',
            expand => "groups,applicationRoles",
            groups => {
                items => [],
                size => 1
            },
            key => "kelonzi",
            locale => "en_US",
            name => "kelonzi",
            self => "$url/rest/api/2/user?username=kelonzi",
            timeZone => "America/New_York"
        }
    ];
}

1;
