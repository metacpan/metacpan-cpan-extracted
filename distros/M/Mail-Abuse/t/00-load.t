
# $Id: 00-load.t,v 1.22 2005/11/03 13:39:27 lem Exp $

use Test::More;

my @modules = qw/
	Mail::Abuse
	Mail::Abuse::Filter
	Mail::Abuse::Reader
	Mail::Abuse::Report
	Mail::Abuse::Incident
	Mail::Abuse::Processor
	Mail::Abuse::Filter::IP
	Mail::Abuse::Reader::POP3
	Mail::Abuse::Filter::Time
	Mail::Abuse::Reader::Stdin
	Mail::Abuse::Incident::Log
	Mail::Abuse::Processor::Table
	Mail::Abuse::Processor::Store
	Mail::Abuse::Processor::Score
	Mail::Abuse::Processor::Mailer
	Mail::Abuse::Processor::Radius
	Mail::Abuse::Incident::SpamCop
	Mail::Abuse::Processor::Explain
	Mail::Abuse::Incident::Received
	Mail::Abuse::Incident::Normalize
	Mail::Abuse::Processor::TableDBI
	Mail::Abuse::Processor::ArchiveDBI
	Mail::Abuse::Incident::MyNetWatchman
	/;
#	Mail::Abuse::Reader::GoogleGroups

plan tests => scalar @modules;

use_ok($_) for @modules;


