package ConfigPathes;

use strict;
use warnings;
use File::Spec;

#modify this to point to your folders
#
#Template data, readable by webserver.
our $templates=File::Spec->catfile('..', 'templates');
#
#Persistent data, writeable by webserver.
our $persistent=File::Spec->catfile('..', 'persistent'); 


#Convienient functions to get a file, don't modify.
sub template {
	return File::Spec->catfile($templates,shift);
}


sub persistent {
	return File::Spec->catfile($persistent,shift);
}

