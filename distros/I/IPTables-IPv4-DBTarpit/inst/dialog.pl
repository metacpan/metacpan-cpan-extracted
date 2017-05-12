#!/usr/bin/perl
#
# dialog.pl for DBTarpit
# version 0.01, 7-24-03
#
# Copyright 2003, Michael Robinton <michael@bizsystems.com>
# rc.dbtarpit is free software; you can redistribute it and/or
# modify it under the terms of the GPL software license.
#
use strict;
use vars qw($CONFIG);
use Cwd 'abs_path';
require 'lib/IPTables/IPv4/DBTarpit/Inst.pm';
import IPTables::IPv4::DBTarpit::Inst qw(:all);

my $conf = 'config.db';
my $localconf = abs_path('./').'/'.$conf;

$CONFIG = (-e $localconf)
	? do $localconf
	: {};

my @defaults = ( # var name		value			prompt
	'DBTP_DAEMON_DIR',	'/usr/local/sbin',	"dbtarpit daemon install directory\t:",
	'DBTP_LIBRARY_DIR',	'/usr/local/lib',	"shared library install directory\t:",
	'DBTP_INCLUDE_DIR',	'/usr/local/include',	"shared library header install directory\t:",
	'DBTP_ENVHOME_DIR',	'/var/run/dbtarpit',	"dbtarpit database env/home directory\t:",
	'DBTP_DB_TARPIT',	'tarpit',		"dbtarpit primary database name  \t:",
	'DBTP_DB_ARCHIVE',	'archive',		"dbtarpit secondary database name\t:",
);

dialog('DBTarpit',$CONFIG,@defaults);
print qq|
	type:	rm $conf
		perl Makefile.PL
	to restore defaults

|;
hard_fail($_) if ($_ = write_conf($localconf,$CONFIG,'DBTP'));
make_text($CONFIG);	# return the Makefile text
