#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '0.01';

#----------------------------------------------------------
# Additional Modules

use lib qw|. ./lib ./plugins|;

use Labyrinth::PSGI;
use Plack::Builder;

#----------------------------------------------------------

my $app = sub {
    my $env = shift;

    my $lab = Labyrinth::PSGI->new( $env, '/var/www/<mywebsite>/cgi-bin/config/settings.ini' );
    return $lab->run();
};

builder {
    enable "Static", path => qr!^/images/!,     root => '../html';
    enable "Static", path => qr!^/(cs|j)s/!,    root => '../html';
    enable "Static", path => qr!^/favicon.ico!, root => '../html';
    enable "Static", path => qr!^/robots.txt!,  root => '../html';
    $app;
};
