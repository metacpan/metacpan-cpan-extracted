#!/usr/bin/env perl

use strict;
use warnings;

use File::Copy;

if(!-r 'lib/Geo/Coder/Free/databases/cities.sql') {
	(system('bash bin/createdatabase') == 0)
		or warn "Can't create the SQLite database - expect poor performance";

	if(-r 'lib/Geo/Coder/Free/databases/cities.sql') {
		copy('lib/Geo/Coder/Free/databases/cities.sql', 'blib/lib/Geo/Coder/Free/databases/cities.sql')
			or die "Can't copy SQLite file to blib";
	}
}
