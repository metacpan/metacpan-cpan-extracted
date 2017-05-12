#!/usr/local/bin/perl

use strict;

use Config::Crontab;

my $c = new Config::Crontab(-owner => 'root');

$_->active(0) for $c->select(-command_re => 'Mail::SpamAssassin::Contrib::Plugin::IPFilter');
$_->active(0) for $c->select(-name => 'MAIL_SPAMASSASSIN_CONTRIB_PLUGIN_IPFILTER');
$c->remove($c->select(-type => 'comment'));
$c->write;

undef $c;

my $c = new Config::Crontab();
$_->active(0) for $c->select(-command_re => 'Mail::SpamAssassin::Contrib::Plugin::IPFilter');
$_->active(0) for $c->select(-name => 'MAIL_SPAMASSASSIN_CONTRIB_PLUGIN_IPFILTER');
$c->remove($c->select(-type => 'comment'));
$c->write;
