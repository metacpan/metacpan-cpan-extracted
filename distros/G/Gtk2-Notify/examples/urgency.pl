#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Notify -init, 'Urgency';

my $n = Gtk2::Notify->new('Low Urgency', 'Joe signed online.');
$n->set_urgency('low');
$n->show;

$n = Gtk2::Notify->new('Normal Urgency', 'You have a meeting in 10 minutes.');
$n->set_urgency('normal');
$n->show;

$n = Gtk2::Notify->new('Critical Urgency', 'This message will self-destruct in 10 seconds.');
$n->set_urgency('critical');
$n->set_timeout(10_000); # 10 seconds
$n->show;
