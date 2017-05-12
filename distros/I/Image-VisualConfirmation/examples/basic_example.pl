#!/usr/bin/perl
# Author: Michele Beltrame
# License: perl5

use strict;
use warnings;

use lib '../lib';

use CGI::Carp qw/fatalsToBrowser/;
use CGI;
use CGI::Session;
use HTML::Tiny;

use Image::VisualConfirmation;

my $query = CGI->new();
my $session = CGI::Session->new($query);
my $h = HTML::Tiny->new(mode => 'html');

# This provides the image file
if ( $query->param('task') eq 'getimage' ) {
    my $vc = Image::VisualConfirmation->new();

    $session->param('vcode', $vc->code);
    $session->flush;
    
    print $session->header(
        -type       => 'image/png'
    );
    print $vc->image_data;
    
    exit 0;
}

print $session->header(
    -type       => 'text/html'
);

# Form processing
my $error = '';
if ( $ENV{REQUEST_METHOD} eq 'POST' ) {
    # Be case insensitive
    my $candidate = lc $query->param('vcode');
    my $comparison = lc $session->param('vcode');
    
    # Strip white space
    $candidate =~ s/^\s+//;
    $candidate =~ s/\s+$//;
    
    if ( $candidate eq $comparison ) {
        print _make_page($h->p([
            $h->strong('OK, you\'re human!')
        ]));
        exit 0;
    }
    
    $error = $h->p({
        style   => 'font-weight:bold;color:red;'
    }, 'Invalid confirmation code');
}

# Form display 
my $form = $h->form({
    method  => 'POST',
    action  => $query->request_uri,
}, [
    $error,
    $h->img({
        src  => $query->request_uri . '?task=getimage'
    }),
    $h->input({
        type => 'text',
        name => 'vcode',
    }),
    $h->input({
        type    => 'submit',
        value   => 'submit',
    }),
]);

print _make_page($form);

exit 0;


sub _make_page {
    my $content = shift;
       
    my $html = '<!DOCTYPE HTML>';
    
    $html .= $h->html([
        $h->head([
            $h->meta({
                'http-equiv'    => 'pragma',
                'content'       => 'no-cache',
            }),
            $h->meta({
                'http-equiv'    => 'expires',
                'content'       => '-1',
            }),
            $h->meta({
                'http-equiv'    => 'content-type',
                'content'       => 'text/html; charset=UTF-8',
            }),
            $h->title('Image::VisualConfirmation CAPTCHA integration demo'),
        ]),
        $h->body([
            $h->div({
                style   => 'width:500px; margin: 0 auto 0 auto',
            }, [
                $h->p('This page is a demonstration for Image::VisualConfirmation'),
                $content,
            ])
        ]),
    ]);
    
    return $html;
}
