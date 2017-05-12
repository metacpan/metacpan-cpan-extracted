#!/usr/bin/env perl

use strict;
use warnings;
my $has_gd = eval { require GD::Simple; 1 };
if ( $has_gd ) {
    GD::Simple->read_color_table if $ENV{MOD_PERL};
    # Surprised? Loading is done via <DATA>, and we neep to do it ASAP
    # before mod_perl tampers with the file handles.
};

# This script demonstrates...
my $descr  = $has_gd ? "Serving raw content, like images" : "";

# Always use latest and greatest Neaf, no matter what's in the @INC
use FindBin qw($Bin);
use File::Basename qw(basename dirname);
use lib dirname($Bin)."/lib";
use MVC::Neaf;

# Add some flexibility to run alongside other examples
my $script = basename(__FILE__);

# And some HTML boilerplate.
my $tpl = <<"TT";
<html><head><title>$descr - $script</title></head>
<body><h1>$script</h1><h2>$descr</h2><hr>
    <h1>Image example</h1>
    <div>
    <form>
        <input type="submit" name="mod" value="--">
        <input type="submit" name="mod" value="++"><br>
        <input name="size" value="[% size %]">
        <input type="submit" value="&gt;&gt;">
    </form>
    </div>
    <img src="/cgi/$script/image.png?size=[% size %]" width="[% size %]" height="[% size %]">
TT

MVC::Neaf->route( cgi => $script => sub {
    my $req = shift;

    my $size = $req->param( size => qr/\d+/, 100 );
    my $mod  = $req->param( 'mod' => qr/.+/, '' );
    $mod =~ /\+/ and $size++;
    $mod =~ /\-/ and $size--;

    $size = 1000 if ($size > 1000); # some safety...
    $size = 10   if ( $size < 10 );

    return {
        size => $size,
        -template => \$tpl,
    };
}, description => $descr);

MVC::Neaf->route( cgi => $script => 'image.png' => sub {
    my $req = shift;
    my $size = $req->param( size => qr/\d+/, 100 );

    my $r = int ($size / 2);
    my $img = GD::Simple->new( $size, $size );
    $img->moveTo ( $r, $r );
    $img->bgcolor('orange');
    $img->ellipse( $size, $size );

    # TODO Add filename when saving
    return {
        -content => $img->png,
        -type    => 'image/png',
    };
});

MVC::Neaf->run;

