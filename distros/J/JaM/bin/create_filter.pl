#!/usr/local/bin/perl

# $Id: create_filter.pl,v 1.6 2001/08/15 19:48:46 joern Exp $

use strict;

BEGIN {
	# find root directory of this JaM installation
	
	# 1. evtl. resolve symbolic link
	my $file = $0;
	while ( -l $file ) {
		my $new_file = readlink $file;
		if ( $new_file =~ m!^/! ) {
			$file = $new_file;
		} else {
			$file =~ s!/[^/]+$!!;
			$file = "$file/$new_file";
		}
	}
		
	# 2. derive root directory from program path
	my $dir = $file;
	$dir =~ s!/?bin/create_filter.pl$!!;
	
	# 3. change to root dir, so paths are reached relative
	#    without more configuration stuff
	chdir $dir if $dir;

	# 4. add lib directory to module search path
	unshift @INC, "lib";
	
}

use DBI;
use JaM::Database;
use JaM::Filter::IO;
use Data::Dumper;

main: {
	my $dbh = JaM::Database->connect;

	if ( not $dbh ) {
		print "Please start jam.pl first, for proper database setup!\n";
		exit 1;
	}

        create_filters (
                dbh => $dbh,
        );
        
        END { $dbh->disconnect if $dbh }
}

sub create_filters {
        my %par = @_;
        my $dbh = $par{'dbh'};
        
        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'zyn@zyn.de',
                folder_path=> "/ZYN!/zyn",
                action => 'drop',
                operation => 'or',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'tofromcc',
                        operation => 'contains',
                        value => 'zyn@zyn.de',
                )

        )->save;
        };
        
        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'zcd@zyn.de',
                folder_path=> "/ZYN!/zcd",
                action => 'drop',
                operation => 'or',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'tofromcc',
                        operation => 'contains',
                        value => 'zcd@zyn.de',
                )

        )->save;
        };

        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'grafik@zyn.de',
                folder_path=> "/ZYN!/gfx",
                action => 'drop',
                operation => 'or',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'tofromcc',
                        operation => 'contains',
                        value => 'grafik@zyn.de',
                )

        )->save;
        };

        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'redaktion@zyn.de',
                folder_path=> "/ZYN!/redaktion",
                action => 'drop',
                operation => 'or',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'tofromcc',
                        operation => 'contains',
                        value => 'redaktion@zyn.de',
                )

        )->save;
        };

        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'rohrpost@zyn.de',
                folder_path=> "/ZYN!/rohrpost",
                action => 'drop',
                operation => 'or',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'tofromcc',
                        operation => 'contains',
                        value => 'rohrpost@zyn.de',
                )

        )->save;
        };

        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'plan-a@zyn.de',
                folder_path=> "/ZYN!/plan-a",
                action => 'drop',
                operation => 'or',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'tofromcc',
                        operation => 'contains',
                        value => 'plan-a@zyn.de',
                )

        )->save;
        };

        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'gnuppel@gmx.net',
                folder_path=> "/gnuppel",
                action => 'drop',
                operation => 'or',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'tocc',
                        operation => 'contains',
                        value => 'gnuppel@gmx.net',
                )

        )->save;
        };

        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'IP Accounting',
                folder_path=> "/Logging/ZYN IP Acc",
                action => 'drop',
                operation => 'or',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'from',
                        operation => 'contains',
                        value => 'root@fries.zyn.de',
                )

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'subject',
                        operation => 'contains',
                        value => 'Report',
                )

        )->save;
        };

        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'Logging / Systemmeldungen',
                folder_path=> "/Logging",
                action => 'drop',
                operation => 'or',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'from',
                        operation => 'contains',
                        value => 'ZYN! System Blockwart',
                )

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'from',
                        operation => 'contains',
                        value => 'root@fries.zyn.de',
                )

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'from',
                        operation => 'contains',
                        value => 'root@prison',
                )

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'from',
                        operation => 'contains',
                        value => 'root@wizard',
                )

        )->save;
        };

        eval {
        JaM::Filter::IO->create (
                dbh => $dbh,
                name => 'Logotomat',
                folder_path=> "/Logging",
                action => 'drop',
                operation => 'and',

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'from',
                        operation => 'contains',
                        value => 'zyn',
                )

        )->append_rule (
                rule => JaM::Filter::IO::Rule->create (
                        field => 'subject',
                        operation => 'contains',
                        value => 'logotomat.pl',
                )

        )->save;
        };

        my $apply = JaM::Filter::IO::Apply->init (
                dbh => $dbh
        );

#        print $apply->code;
}
