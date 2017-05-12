#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 10;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/yaml.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

is($ebug->finished, 0);
is($ebug->line, 3);
is($ebug->subroutine, "main");
$ebug->next;

is($ebug->finished, 0);
is($ebug->line, 4);
is($ebug->subroutine, "main");
$ebug->next;

is($ebug->finished, 0);
is($ebug->line, 5);
is($ebug->subroutine, "main");
$ebug->next;

is($ebug->finished, 1);
