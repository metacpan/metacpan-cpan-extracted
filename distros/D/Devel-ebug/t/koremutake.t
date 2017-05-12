#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 3;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/koremutake.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;
$ebug->run;

$ebug = Devel::ebug->new;
$ebug->program("t/koremutake.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;
my $filename = (grep { $_ =~ /Koremutake/ } $ebug->filenames)[0];
ok($filename);
$ebug->break_point_subroutine("String::Koremutake::integer_to_koremutake");
$ebug->run;
is($ebug->subroutine, "String::Koremutake::integer_to_koremutake");
is($ebug->filename, $filename);
$ebug->run;
