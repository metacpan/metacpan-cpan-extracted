#!/usr/bin/perl 
use strict;
use warnings;
use Email::Filter;
use Email::Filter::Rules;

my $maildir    = '/home/jbisbee/mail/';
my $msg        = Email::Filter->new( emergency => $maildir . 'emergency' );
my $mail_lists = Email::Filter::Rules->new( rules => 'filter.txt' );

if ( my $mail_list_folder = $mail_lists->apply_rules($msg) ) {
    $msg->accept( $maildir . $mail_list_folder );
}

$msg->accept( $maildir . 'inbox' );
