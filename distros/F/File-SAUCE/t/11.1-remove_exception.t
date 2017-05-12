use Test::More tests => 4;

use strict;
use warnings;

use_ok( 'File::SAUCE' );

my $sauce = File::SAUCE->new;
isa_ok( $sauce, 'File::SAUCE' );

{
    my $warnings = 0;
    local $SIG{ __WARN__ } = sub { $warnings++ };
    open( my $file, 't/data/NA-SEVEN.CIA' );
    $sauce->remove( handle => $file );
    ok( $warnings, 'Remove (fail - read only [CASE 1])' );
    close( $file );
}

{
    my $warnings = 0;
    local $SIG{ __WARN__ } = sub { $warnings++ };
    open( my $file, 't/data/spoon.dat' );
    $sauce->remove( handle => $file );
    ok( $warnings, 'Remove (fail - read only [CASE 2])' );
    close( $file );
}
