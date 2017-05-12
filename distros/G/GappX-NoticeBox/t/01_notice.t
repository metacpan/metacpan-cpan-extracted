#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More qw( no_plan );

use Gapp;


{ # basic test
    use_ok 'GappX::Notice';
    my $w = GappX::Notice->new;
    ok $w, 'created gapp window';
    ok $w->gobject, 'created gtk widget';
}



{ # basic test
    use_ok 'GappX::NoticeBox';
    my $w = GappX::NoticeBox->new;
    ok $w, 'created gapp window';
    ok $w->gobject, 'created gtk widget';
    
    my $notice = GappX::Notice->new(
        text => 'Hello World!',
        action => Gapp::Action->new( code => sub { print qq[action\n] } ),
    );
    $w->display( $notice );
    
    Glib::Timeout->add(5000, sub {
        $w->hide;
    });
}

