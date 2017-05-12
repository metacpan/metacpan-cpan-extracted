#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;

package Foo;

use Test::More;

use Gapp::Moose;
use_ok 'GappX::Moose::Meta::Attribute::Trait::GappNoticeBox';

use GappX::NoticeBox;

widget 'bar' => (
    is => 'ro',
    traits => [qw( GappNoticeBox)],
    construct => 1,
);

package main;


my $o = Foo->new;
isa_ok $o->bar, 'GappX::NoticeBox';