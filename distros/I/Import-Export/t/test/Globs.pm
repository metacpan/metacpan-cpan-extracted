package Globs;

use strict;
use warnings;

use base qw/Import::Export/;

our %EX = (
	"*zzx" => [qw/all/],
);

sub zzx { 'Hello World' }

1;
