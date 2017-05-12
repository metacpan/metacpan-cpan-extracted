use strict;
use Error qw(:try);
use File::Compare;
use File::Spec;
use Test::More tests => 5;

# 1) Test use
BEGIN { use_ok( 'InfoSys::FreeDB::Entry', 'use InfoSys::FreeDB::Entry' ); }

# 2) Test new_from_fn
my $file_1 = File::Spec->catfile( 'sample', 'jaco-test-in.entry');
my $entry;
try {
    $entry = InfoSys::FreeDB::Entry->new_from_fn( $file_1 );
}
catch Error::Simple with {
    ok( 0, "new_from_fn( $file_1 )" );
    ok( 0 );
    ok( 0 );
    ok( 0 );
};
ok( 1, "new_from_fn( $file_1 )" );

# 3) Make tmp dir
my $fn = File::Spec->catfile( 't', 'tmp' );
if ( -d $fn || mkdir( $fn ) ) {
    ok( 1, "mkdir $fn" );
}
else {
    ok( 0, "mkdir $fn" );
    ok( 0 );
    ok( 0 );
}

# 4) Test write_fn
my $file_2 = File::Spec->catfile( 't', 'tmp', 'jaco-test-out.entry');
try {
    $entry->write_fn( $file_2 );
}
catch Error::Simple with {
    ok( 0, "writing file $file_2" );
    ok( 0 );
};
ok( 1 );

# 5) Diff entry files
if ( compare( $file_1, $file_2 ) ) {
    ok( 0, "compare $file_1 and $file_2" );
}
else {
    ok( 1, "compare $file_1 and $file_2" );
}
