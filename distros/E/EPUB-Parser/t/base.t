use Test::More;
use strict;
use warnings;
use EPUB::Parser;
use Archive::Zip qw/ AZ_OK /;

my $zip = Archive::Zip->new();
is($zip->read( 't/var/denden_converter.epub' ) , AZ_OK, 'read zip file');

my $ep = EPUB::Parser->new;
is( ref $ep, 'EPUB::Parser', 'EPUB::Parser->new');

done_testing;
