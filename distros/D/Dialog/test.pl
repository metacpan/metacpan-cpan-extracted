#!/usr/bin/perl

# $Id: test.pl,v 1.1 2000/06/06 07:05:36 mike_s Exp $

use Dialog;
use Dialog::Const;
use strict;

my @hosts = ("11\0host1", "host2", "a\0host3", "*\0host4");
my %hosts = (
  "11" => "Host 1",
  "host2" => "Host 2",
  "a" => "Host 3",
  "*" => "Host 4",
);

my @radio = ("Radio1", "2\0Radio2", "X\0Radio3");
#my @radio = ("Radio1", "Radio2", "Radio3");

my $dlg = Dialog->new('Clients', 5, 10, 15, 60);
my $il_host = $dlg->inputline("il_host", 2, 3, 50);
$dlg->label("label1", 2, 4, "Client host");
my $il_desc = $dlg->inputline("il_name", 5, 3, 50);
$dlg->label("label2", 5, 4, "Description");
$dlg->button("bt_ok", 11, 25, "  &Ok  ", mrOk);
$dlg->button("bt_cancel", 11, 39, "C&ancel", mrCancel);

Dialog::Clear();
my $host = Dialog::Menu('Edit host', 'Choose host to edit',
  20, 30, 13, @hosts);

Dialog::Clear();
my $radio = Dialog::RadioList('Radio demo', 'Pick one of the options',
  20, 30, 13, @radio);

Dialog::Clear();
$il_host->data($host);
$il_desc->data($hosts{$host});
$dlg->redraw;
$dlg->run;

my $desc = $il_desc->data;
Dialog::gotoyx(24, 0);
undef $dlg;
print "Radio: $radio\nHost: $host\nDesc: $desc\n";
1;