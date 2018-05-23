# File::pushd - check module loading and create testing directory
use strict;
#use warnings;

use Test::More 0.96;
use File::Path 'rmtree';
use File::Basename 'dirname';
use Cwd 'abs_path';
use File::Spec::Functions qw( catdir curdir updir canonpath rootdir );
use File::Temp;
use Config '%Config';

# abs_path necessary to pick up the volume on Win32, e.g. C:\
sub absdir { canonpath( abs_path( shift || curdir() ) ); }

#--------------------------------------------------------------------------#
# Test import
#--------------------------------------------------------------------------#

BEGIN { use_ok('File::pushd'); }
can_ok( 'main', 'pushd', 'tempd' );

#--------------------------------------------------------------------------#
# Setup
#--------------------------------------------------------------------------#

my ( $new_dir, $temp_dir, $err );
my $original_dir = absdir();
my $target_dir   = 't';
my $expected_dir = absdir( catdir( $original_dir, $target_dir ) );
my $nonexistant  = 'DFASDFASDFASDFAS';

#--------------------------------------------------------------------------#
# Test error handling on bad target
#--------------------------------------------------------------------------#

eval { $new_dir = pushd($nonexistant) };
$err = $@;
like( $@, '/\\ACan\'t/', "pushd to nonexistant directory croaks" );

#--------------------------------------------------------------------------#
# Test changing to relative path directory
#--------------------------------------------------------------------------#

$new_dir = pushd($target_dir);

isa_ok( $new_dir, 'File::pushd' );

is( absdir(), $expected_dir, "change directory on pushd (relative path)" );

#--------------------------------------------------------------------------#
# Test stringification
#--------------------------------------------------------------------------#

is( "$new_dir", $expected_dir, "object stringifies" );

#--------------------------------------------------------------------------#
# Test reverting directory
#--------------------------------------------------------------------------#

undef $new_dir;

is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

#--------------------------------------------------------------------------#

# Test changing to absolute path directory and reverting
#--------------------------------------------------------------------------#

$new_dir = pushd($expected_dir);
is( absdir(), $expected_dir, "change directory on pushd (absolute path)" );

undef $new_dir;
is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

#--------------------------------------------------------------------------#
# Test changing upwards
#--------------------------------------------------------------------------#

$expected_dir = absdir( updir() );
$new_dir      = pushd( updir() );

is( absdir(), $expected_dir, "change directory on pushd (upwards)" );
undef $new_dir;
is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

#--------------------------------------------------------------------------#
# Test changing to root
#--------------------------------------------------------------------------#

$new_dir = pushd( rootdir() );

is( absdir(), absdir( rootdir() ), "change directory on pushd (rootdir)" );
undef $new_dir;
is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

#--------------------------------------------------------------------------#
# Test with options
#--------------------------------------------------------------------------#

$new_dir = pushd( $expected_dir, { untaint_pattern => qr{^([-\w./]+)$} } );
is( absdir(), $expected_dir, "change directory on pushd (custom untaint)" );
undef $new_dir;
is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

#--------------------------------------------------------------------------#
# Test changing in place
#--------------------------------------------------------------------------#

$new_dir = pushd();

is( absdir(), $original_dir, "pushd with no argument doesn't change directory" );
chdir "t";
is(
    absdir(),
    absdir( catdir( $original_dir, "t" ) ),
    "changing manually to another directory"
);
undef $new_dir;
is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

#--------------------------------------------------------------------------#
# Test changing to temporary dir
#--------------------------------------------------------------------------#

$new_dir  = tempd();
$temp_dir = "$new_dir";

ok( absdir() ne $original_dir, "tempd changes to new temporary directory" );

undef $new_dir;
is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

ok( !-e $temp_dir, "temporary directory removed" );

#--------------------------------------------------------------------------#
# Test changing to temporary dir but preserving it
#--------------------------------------------------------------------------#

$new_dir  = tempd();
$temp_dir = "$new_dir";

ok( absdir() ne $original_dir, "tempd changes to new temporary directory" );

ok( $new_dir->preserve(1), "mark temporary directory for preservation" );

undef $new_dir;
is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

ok( -e $temp_dir, "temporary directory preserved" );

ok( rmtree($temp_dir), "temporary directory manually cleaned up" );

#--------------------------------------------------------------------------#
# Test changing to temporary dir but preserving it *outside the process*
#--------------------------------------------------------------------------#

my $program_file = File::Temp->new();
my $lib          = absdir("lib");
$lib =~ s{\\}{/}g;

print {$program_file} <<"END_PROGRAM";
use lib "$lib";
use File::pushd;
my \$tempd = tempd() or exit;
\$tempd->preserve(1);
print "\$tempd\n";
END_PROGRAM

$program_file->close;

# for when I manually test with "perl -t", must untaint things
for my $key (qw(IFS CDPATH ENV BASH_ENV PATH)) {
    next unless defined $ENV{$key};
    $ENV{$key} =~ /^(.*)$/;
    $ENV{$key} = $1;
}

$temp_dir = `$^X $program_file`;

chomp($temp_dir);

$temp_dir =~ /(.*)/;
my $clean_tmp = $1;

ok( length $clean_tmp, "got a temp directory name from subproces" );

ok( -e $clean_tmp, "temporary directory preserved outside subprocess" );

ok( rmtree($clean_tmp), "temporary directory manually cleaned up" );

#--------------------------------------------------------------------------#
# Test changing to temporary dir, preserve it, then revert
#--------------------------------------------------------------------------#

$new_dir  = tempd();
$temp_dir = "$new_dir";

ok( absdir() ne $original_dir, "tempd changes to new temporary directory" );

ok( $new_dir->preserve,     "mark temporary directory for preservation" );
ok( !$new_dir->preserve(0), "mark temporary directory for removal" );

undef $new_dir;
is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

ok( !-e $temp_dir, "temporary directory removed" );
#--------------------------------------------------------------------------#
# Test preserve failing on non temp directory
#--------------------------------------------------------------------------#

$new_dir = pushd( catdir( $original_dir, $target_dir ) );

is(
    absdir(),
    absdir( catdir( $original_dir, $target_dir ) ),
    "change directory on pushd"
);
$temp_dir = "$new_dir";

ok( $new_dir->preserve,    "regular pushd is automatically preserved" );
ok( $new_dir->preserve(0), "can't mark regular pushd for deletion" );

undef $new_dir;
is( absdir(), $original_dir, "revert directory when variable goes out of scope" );

ok( -e $expected_dir, "original directory not removed" );

#--------------------------------------------------------------------------#
# Test removing temp directory by owner process
#--------------------------------------------------------------------------#
if ( $Config{d_fork} ) {
    my $new_dir = tempd();
    my $temp_dir = "$new_dir";
    my $pid = fork;
    die "Can't fork: $!" unless defined $pid;
    if ($pid == 0) {
        exit;
    }
    wait;
    ok( -e $temp_dir, "temporary directory not removed by child process" );
    undef $new_dir;
    ok( !-e $temp_dir, "temporary directory removed by owner process" );
}

done_testing;
