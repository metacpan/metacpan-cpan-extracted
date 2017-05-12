# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 005-Directives.t'

#########################

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Games::Go::AGA::DataObjects::Directives') };

my $directives = Games::Go::AGA::DataObjects::Directives->new(
                );
isa_ok ($directives, 'Games::Go::AGA::DataObjects::Directives', 'create object');

