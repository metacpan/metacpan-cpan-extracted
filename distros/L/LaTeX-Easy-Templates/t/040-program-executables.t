#!/usr/bin/env perl

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

our $VERSION = '0.04';

use Test::More;
use Test::More::UTF8;
use FindBin;
use File::Spec;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 1;

my $curdir = $FindBin::Bin;

# let's see what executables we have available
my $executas = LaTeX::Easy::Templates::latex_driver_executable();
ok(defined($executas), 'LaTeX::Easy::Templates::latex_driver_executable()'." : called and got success.") or BAIL_OUT;
for (keys %$executas){
	diag "Program executable: $_ => ".$executas->{$_}
}

# END
done_testing();
