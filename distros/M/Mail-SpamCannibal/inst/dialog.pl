#!/usr/bin/perl
# dialog.pl for SpamCannibal
# version 0.02, 8-13-03
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

new IPTables::IPv4::DBTarpit::SiteConfig;


my @defaults = ( # var name		value				prompt
	'SPMCNBL_ENVIRONMENT',	'/var/run/dbtarpit',		"spamcannibal db environment directory\t:",
	'SPAMCANNIBAL_USER',	'spam',				"spamcannibal user (must already exist)\t:",
	'SPAMCANNIBAL_HOME',	'/usr/local/spamcannibal', 	"spamcannibal user home directory\t:",
	'SPMCNBL_DB_TARPIT',	'tarpit',			"spamcannibal tarpit database name\t:",
	'SPMCNBL_DB_ARCHIVE',	'archive',			"spamcannibal archive database name\t:",
	'SPMCNBL_DB_CONTRIB',	'blcontrib',			"spamcannibal black list contrib name\t:",
	'SPMCNBL_DB_EVIDENCE',	'evidence',			"spamcannibal evidence database name\t:",
	'SPAMCANNIBAL_UMASK',	'007',				"spamcannibal default umask (007)\t:",
);

dialog('SpamCannibal',$CONFIG,@defaults);
print q
|If you wish to support additional databases, edit
the rc.xxxx startup script for the appropriate program.

|;

$CONFIG->{SPMCNBL_DAEMON_DIR} = $CONFIG->{SPAMCANNIBAL_HOME} .'/bin';
$CONFIG->{SPMCNBL_CONFIG_DIR} = $CONFIG->{SPAMCANNIBAL_HOME} .'/config';
$CONFIG->{SPMCNBL_SCRIPT_DIR} = $CONFIG->{SPAMCANNIBAL_HOME} .'/scripts';

verify($CONFIG);
write_conf($localconf,$CONFIG,'SP');
make_text($CONFIG);	# return the Makefile text
