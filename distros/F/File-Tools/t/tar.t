#!/usr/bin/perl -w
use strict;

use Test::More skip_all => 'Not implemented yet.';
use Test::NoWarnings;

use File::Tools;


# tar should probably provide the basic facilities directly and if the user needs deeper
# things s/he will need to learn the learn the real Arcive::Tar
tar "-x", "filename.tar";
tar "-c", "filename.tar", "directory";

tar {action => "x"}, "filename.tar";


