use strict;

use File::Find            qw(find);
use File::Spec::Functions qw(curdir);

use vars qw( $expected_count );

BEGIN {
	$expected_count = 0;
	
	find( sub { if( -s $_ == 0 ) { return if $_ eq "."; $expected_count++ } }, 
		curdir() );

	}

use Test::More tests => 9 + $expected_count;

use_ok( "File::Find::Closures" );

ok( defined *File::Find::Closures::find_by_zero_size{CODE}, 
	"file_by_name is defined" );

my( $finder, $reporter ) = File::Find::Closures::find_by_zero_size();
isa_ok( $finder,   'CODE' );
isa_ok( $reporter, 'CODE' );

find( $finder, curdir() );

my @files = $reporter->();
my $files = $reporter->();
isa_ok( $files, 'ARRAY', "Gets anonymous array in scalar context" );

# zero size files in the dist: .exists (in many directories) pm_to_blib

is( scalar @files, $expected_count, "Found five files" );
foreach my $file ( @files )
	{
	is( -s $file, 0, "$file is zero bytes" );
	}

my @found = grep /pm_to_blib/, @files;
like( $found[0], qr/pm_to_blib/, "Found pm_to_blib" );

is( scalar @$files, $expected_count, "Found five files" );
@found = grep /pm_to_blib/, @$files;

like( $found[0], qr/pm_to_blib/, "Found pm_to_blib" );
