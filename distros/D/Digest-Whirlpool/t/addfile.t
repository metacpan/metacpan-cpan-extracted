use strict;

use Test::More tests => 1;

use File::Spec;
use Digest::Whirlpool;

my $path = File::Spec->catfile( qw< t file.test > );

open INFILE, $path;

my $whirlpool = Digest::Whirlpool->new;

$whirlpool->addfile( *INFILE );

like $whirlpool->clone->hexdigest, qr/^f1d/, "adding two items to the first one";
