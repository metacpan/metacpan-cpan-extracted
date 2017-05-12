#!/usr/bin/perl
#
# dialog.pl for DNSBLserver
# version 0.01, 7-24-03
#
# Copyright 2003, Michael Robinton <michael@bizsystems.com>
# rc.dbtarpit is free software; you can redistribute it and/or
# modify it under the terms of the GPL software license.
#
use strict;
#use diagnostics;
use vars qw($CONFIG);
use Cwd 'abs_path';
use IPTables::IPv4::DBTarpit::Inst qw(:all);
use IPTables::IPv4::DBTarpit::SiteConfig;

my $conf = 'config.db';
my $localconf = abs_path('./').'/'.$conf;

if ( -e $localconf ) {
  $CONFIG = do $localconf if -e $localconf;
  my $dbtarpit = new IPTables::IPv4::DBTarpit::SiteConfig;
  foreach(keys %$dbtarpit) {
    $CONFIG->{$_} = $dbtarpit->{$_};;
  }
} else {
  $CONFIG = new IPTables::IPv4::DBTarpit::SiteConfig;
}

my @defaults = ( # var name		value				prompt
	'SPAMCANNIBAL_HOME',	'/usr/local/spamcannibal',	"spamcannibal user home directory\t:",
	'SPMCNBL_ENVIRONMENT',	'/var/run/dbtarpit',		"spamcannibal db environment directory\t:",
	'SPMCNBL_DB_TARPIT',	'tarpit',			"spamcannibal tarpit database name\t:",
	'SPMCNBL_DB_CONTRIB',	'blcontrib',			"spamcannibal black list contrib name\t:",
);

dialog('SpamCannibal',$CONFIG,@defaults);
$CONFIG->{SPMCNBL_DAEMON_DIR} = $CONFIG->{SPAMCANNIBAL_HOME} .'/bin';
$CONFIG->{SPMCNBL_CONFIG_DIR} = $CONFIG->{SPAMCANNIBAL_HOME} .'/config';
verify($CONFIG);

hard_fail($_) if ($_ = write_conf($localconf,$CONFIG,'SP'));
make_text($CONFIG);	# return the Makefile text
