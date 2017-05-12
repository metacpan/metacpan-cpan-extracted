#!/usr/bin/perl -w
use warnings;
use strict;
use Test::More tests => 16;
use Test::Differences;

sub parse_tree_ok {
    my ($received, $expect, $name) = @_;
    eq_or_diff $received->parse_tree, $expect, $name
      or note $received->diagnostics;
}

BEGIN { use_ok('Mail::Field::Received'); }
my $received = Mail::Field->new('Received');
isa_ok $received, 'Mail::Field::Received';
is $received->tag, 'Received', 'tag';
$received->debug(5);
is $received->debug, 5, 'debug level';

# date format 3
my $in =
'from tr909.mediaconsult.com (mediacons.tecc.co.uk [193.128.6.132]) by host5.hostingcheck.com (8.9.3/8.9.3) with ESMTP id VAA24164 for <adam@spiers.net>; Tue, 1 Feb 2000 21:57:18 -0500';
my $parse_tree = {
    'by' => {
        'domain'   => 'host5.hostingcheck.com',
        'whole'    => 'by host5.hostingcheck.com',
        'comments' => ['(8.9.3/8.9.3)'],
    },
    'date_time' => {
        'year'        => '2000',
        'week_day'    => 'Tue',
        'minute'      => '57',
        'day_of_year' => '1 Feb',
        'month_day'   => ' 1',
        'zone'        => '-0500',
        'second'      => '18',
        'hms'         => '21:57:18',
        'date_time'   => 'Tue, 1 Feb 2000 21:57:18 -0500',
        'hour'        => '21',
        'month'       => 'Feb',
        'rest'        => '2000 21:57:18 -0500',
        'whole'       => 'Tue, 1 Feb 2000 21:57:18 -0500'
    },
    'with' => {
        'with'  => 'ESMTP',
        'whole' => 'with ESMTP'
    },
    'from' => {
        'domain'   => 'mediacons.tecc.co.uk',
        'HELO'     => 'tr909.mediaconsult.com',
        'from'     => 'tr909.mediaconsult.com',
        'address'  => '193.128.6.132',
        'comments' => [ '(mediacons.tecc.co.uk [193.128.6.132])', ],
        'whole' =>
          'from tr909.mediaconsult.com (mediacons.tecc.co.uk [193.128.6.132])
'
    },
    'id' => {
        'id'    => 'VAA24164',
        'whole' => 'id VAA24164'
    },
    'comments' => [ '(mediacons.tecc.co.uk [193.128.6.132])', '(8.9.3/8.9.3)' ],
    'for'      => {
        'for'   => '<adam@spiers.net>',
        'whole' => 'for <adam@spiers.net>'
    },
    'whole' =>
'from tr909.mediaconsult.com (mediacons.tecc.co.uk [193.128.6.132]) by host5.hostingcheck.com (8.9.3/8.9.3) with ESMTP id VAA24164 for <adam@spiers.net>; Tue, 1 Feb 2000 21:57:18 -0500'
};
$received->parse($in);
is $received->parsed_ok, 1, 'date format 3 parsed ok';
parse_tree_ok($received, $parse_tree, 'date format 3 parse tree');

# date format 3 again
$in         = '(qmail 7119 invoked from network); 22 Feb 1999 22:01:53 -0000';
$parse_tree = {
    'date_time' => {
        'year'        => '1999',
        'week_day'    => undef,
        'minute'      => '01',
        'day_of_year' => '22 Feb',
        'month_day'   => '22',
        'zone'        => '-0000',
        'second'      => '53',
        'date_time'   => '22 Feb 1999 22:01:53 -0000',
        'hms'         => '22:01:53',
        'hour'        => '22',
        'month'       => 'Feb',
        'rest'        => '1999 22:01:53 -0000',
        'whole'       => '22 Feb 1999 22:01:53 -0000'
    },
    'comments' => ['(qmail 7119 invoked from network)'],
    'whole' => '(qmail 7119 invoked from network); 22 Feb 1999 22:01:53 -0000'
};
$received->parse($in);
is $received->parsed_ok, 1, 'date format 3 again parsed ok';
parse_tree_ok($received, $parse_tree, 'date format 3 again parse tree');

# date format 1
my $new_date      = '22 Feb';
my $new_rest      = '22:01:53 1999 -0000';
my $new_date_time = "$new_date $new_rest";
$in = "(qmail 7119 invoked from network); $new_date_time";
$parse_tree->{date_time}{whole}     = $new_date_time;
$parse_tree->{date_time}{date_time} = $new_date_time;
$parse_tree->{date_time}{rest}      = $new_rest;
$parse_tree->{whole}                = $in;
$received->parse($in);
is $received->parsed_ok, 1, 'date format 1 parsed ok';
parse_tree_ok($received, $parse_tree, 'date format 1 parse tree');

# date format 2
$new_date      = '22 Feb';
$new_rest      = '22:01:53 -0000 1999';
$new_date_time = "$new_date $new_rest";
$in            = "(qmail 7119 invoked from network); $new_date_time";
$parse_tree->{date_time}{whole}     = $new_date_time;
$parse_tree->{date_time}{date_time} = $new_date_time;
$parse_tree->{date_time}{rest}      = $new_rest;
$parse_tree->{whole}                = $in;
$received->parse($in);
is $received->parsed_ok, 1, 'date format 2 parsed ok';
parse_tree_ok($received, $parse_tree, 'date format 2 parse tree');

# IP-based hostname
TODO: {
    local $TODO = 'parsing IP-based hostname fails (see RT #51169)';
    $in =
'Received: from 140.85.213.193.static.cust.telenor.com ([193.213.85.140]) by einstein.junkemailfilter.com with esmtp (Exim 4.69) id 1N63Ug-0008GI-Vp on interface=64.71.167.93 for xxxxx@xxxxxcom; Thu, 05 Nov 2009 06:39:23 -0800';
    $received->parse($in);
    is $received->parsed_ok, 1, 'IP-based hostname parsed ok';

    # parse_tree_ok($received, $parse_tree, 'date format 2 parse tree');
}

# alternate constructor call
$in =
'from lists.securityfocus.com (lists.securityfocus.com [207.126.127.68]) by lists.securityfocus.com (Postfix) with ESMTP id 1C2AF1F138; Mon, 14 Feb 2000 10:24:11 -0800 (PST)';
$parse_tree = {
    'by' => {
        'domain'   => 'lists.securityfocus.com',
        'whole'    => 'by lists.securityfocus.com',
        'comments' => ['(Postfix)'],
    },
    'date_time' => {
        'year'        => '2000',
        'week_day'    => 'Mon',
        'minute'      => '24',
        'day_of_year' => '14 Feb',
        'month_day'   => '14',
        'zone'        => '-0800 (PST)',
        'second'      => '11',
        'date_time'   => 'Mon, 14 Feb 2000 10:24:11 -0800 (PST)',
        'hour'        => '10',
        'hms'         => '10:24:11',
        'month'       => 'Feb',
        'rest'        => '2000 10:24:11 -0800 (PST)',
        'whole'       => 'Mon, 14 Feb 2000 10:24:11 -0800 (PST)'
    },
    'with' => {
        'with'  => 'ESMTP',
        'whole' => 'with ESMTP'
    },
    'from' => {
        'domain'   => 'lists.securityfocus.com',
        'from'     => 'lists.securityfocus.com',
        'HELO'     => 'lists.securityfocus.com',
        'address'  => '207.126.127.68',
        'comments' => [ '(lists.securityfocus.com [207.126.127.68])', ],
        'whole' =>
'from lists.securityfocus.com (lists.securityfocus.com [207.126.127.68])
'
    },
    'id' => {
        'id'    => '1C2AF1F138',
        'whole' => 'id 1C2AF1F138'
    },
    'comments' => [ '(lists.securityfocus.com [207.126.127.68])', '(Postfix)' ],
    'whole' =>
'from lists.securityfocus.com (lists.securityfocus.com [207.126.127.68]) by lists.securityfocus.com (Postfix) with ESMTP id 1C2AF1F138; Mon, 14 Feb 2000 10:24:11 -0800 (PST)'
};
my $received2 = Mail::Field->new('Received', $in);
is $received2->parsed_ok, 1, 'alternate constructor parsed ok';
parse_tree_ok($received2, $parse_tree, 'alternate constructor parse tree');
$received2->diagnose('squr', 'gle');
like $received2->diagnostics, qr/^squrgle$/m, 'diagnostics';
