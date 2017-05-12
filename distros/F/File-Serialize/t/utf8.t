use strict;
use utf8;

use Test::More;
use Test::Warnings 'warning';
use Test::Requires 'JSON::MaybeXS';

use Path::Tiny;

use File::Serialize;

my $data = { a => "Kohl’s" };
my $file = Path::Tiny->tempfile( SUFFIX => '.json' );

my $warning = warning { serialize_file( $file => $data , { utf8 => 0 } ) };
like( $warning , qr/Wide character in print/ , 'Expected wide char warning' )
   or diag 'got warning(s): ', explain($warning);

# just run to verify no warnings with default utf8 => 1
serialize_file( Path::Tiny->tempfile( SUFFIX => '.json' ) => $data );

done_testing();
