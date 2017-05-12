#!/usr/bin/env perl

use strict;
use warnings;

# This example demonstrates Neaf's hooks by adding two hooks around its main
# logic which calculate the time spent in controller.

# Always use latest & greatest Neaf
use Time::HiRes qw(time);
use File::Basename qw(basename dirname);
use lib dirname(__FILE__)."/../lib";
use MVC::Neaf;

# Take a self-reference for convenience
my $script = "/cgi/".basename(__FILE__);

my $tpl = <<TT;
<html><head><title>Hook demo</title></head>
<body>
<h1>Hook demo</h1>
<h2>Request processed in [% time %] seconds</h2>
</body></html>
TT

# make an empty route
MVC::Neaf->route( $script => sub {
    +{}
}, description => "Hook demo");

MVC::Neaf->load_view( TT => TT => INCLUDE_PATH => dirname(__FILE__) );

# set our template as default for this path as below
MVC::Neaf->set_path_defaults( $script => { -template => basename(__FILE__).".tt" } );

# calculate time spent. Note $req->stash usage as temporary storage
MVC::Neaf->add_hook(
    pre_logic => sub { $_[0]->stash->{t0} = time },
    path => $script );
MVC::Neaf->add_hook(
    pre_render => sub { $_[0]->reply->{time} = time - $_[0]->stash->{t0} },
    path => $script );

# Run the application
MVC::Neaf->run;
