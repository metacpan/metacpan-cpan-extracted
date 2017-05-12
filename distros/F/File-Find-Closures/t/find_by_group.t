# $Id$
use strict;

use File::Find            qw(find);
use File::Spec::Functions qw(curdir);

use Test::More tests => 2;

use_ok( "File::Find::Closures" );

{
no warnings;
ok( defined *File::Find::Closures::find_by_group{CODE}, 
	"file_by_group is defined" );
}