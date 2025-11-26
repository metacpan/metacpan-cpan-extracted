#!/usr/bin/env perl

use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util qw(::OS ::Query ::File);

use Socket;

# plan tests => 57;  # plan not set because some tests are OS or user_id dependent

#======================================#
#           Make test files            #
#======================================#

my $test_file = 't/perlcriticrc';

my $td = mk_temp_dir();
my $tf = mk_temp_file($td);

my $no_file = '/nonexistant_file';
my $no_dir  = '/nonexistant_dir';

my $tff = $td . "/tempfile.$$.test";
open( my $tff_h, '>', $tff ) or croak "Can't open file for writing\n";
print { $tff_h } "Owner Persist\nIris Seven\n#Fence\n\n";
close($tff_h);

my $tsl = $td . "/symlink.$$.test";
symlink( $tff, $tsl );

socket( my $ts, PF_INET, SOCK_STREAM, ( getprotobyname('tcp') )[2] );
my $trf = '/bin/cat';
my $dnf = '/dev/null';

#======================================#
#             file_exists              #
#======================================#

is( file_exists($tf), 1, 'file_exists - exigent file returns true' );
is( file_exists($no_file), 0,
    'file_exists - non-existant file returns false' );

#======================================#
#            file_readable             #
#======================================#

my $mode = oct(0000);
chmod $mode, $tff;
SKIP: {
    skip "Root user - test not valid", 1 if ( $REAL_USER_ID == 0 );
    is( file_readable($tff), 0,
        'file_readable - non-readable file returns false' );
}
$mode = oct(400);
chmod $mode, $tff;
is( file_readable($tff), 1, 'file_readable - readable file returns true' );

#======================================#
#            file_writable             #
#======================================#

SKIP: {
    skip "Root user - test not valid", 1 if ( $REAL_USER_ID == 0 );
    is( file_writable($tff), 0,
        'file_writable - non-writable file returns false' );
}
$mode = oct(200);
chmod $mode, $tff;
is( file_writable($tf), 1, 'file_writable - writable file returns true' );

#======================================#
#           file_executable            #
#======================================#

is( file_executable($tff), 0,
    'file_executable - non-executable file returns false' );
$mode = oct(100);
chmod $mode, $tff;
is( file_executable($tff), 1,
    'file_executable - executable file returns true' );

#======================================#
#            file_is_empty             #
#======================================#

is( file_is_empty($dnf), 1, 'file_is_empty - empty file returns true' );
is( file_is_empty($tff), 0, 'file_is_empty - non-empty file returns false' );

#======================================#
#           file_size_equals           #
#======================================#

is( file_size_equals( $tff, 33 ),
    1, 'file_size_equals - correct size returns true' );
is( file_size_equals( $td, 1 ),
    0, 'file_size_equals - incorrect size returns false' );
is( file_size_equals( $no_file, 1 ),
    0, 'file_size_equals - non-existant file returns false' );

#======================================#
#         file_owner_effective         #
#======================================#

is( file_owner_effective($tf),
    1, 'file_owner_effective - file owned by eff id returns true' );
SKIP: {
    skip "Root user - test not valid", 1 if ( $REAL_USER_ID == 0 );
    is( file_owner_effective($trf),
        0, 'file_owner_effective - file not owned by eff id returns false' );
}

#======================================#
#           file_owner_real            #
#======================================#

is( file_owner_real($tf), 1,
    'file_owner_real - file owned by real id returns true' );
SKIP: {
    skip "Root user - test not valid", 1 if ( $REAL_USER_ID == 0 );
    is( file_owner_real($trf), 0,
        'file_owner_real - file not owned by real id returns false' );
}

#======================================#
#            file_is_setuid            #
#======================================#

is( file_is_setuid($tff), 0,
    'file_is_setuid - non-setuid file returns false' );

$mode = oct(4444);
my $chmod_suid_result = chmod $mode, $tff;
SKIP: {
    skip "Could not set setuid bit on test file", 1 unless ($chmod_suid_result);
    is( file_is_setuid($tff), 1, 'file_is_setuid - setuid file returns true' );
}

#======================================#
#            file_is_setgid            #
#======================================#

is( file_is_setgid($tff), 0,
    'file_is_setgid - non-setgid file returns false' );

$mode = oct(2444);
my $chmod_guid_result = chmod $mode, $tff;
SKIP: {
    skip "Could not set setgid bit on test file", 1 unless ($chmod_guid_result);
    is( file_is_setgid($tff), 1, 'file_is_setgid - setgid file returns true' );
}

#======================================#
#            file_is_sticky            #
#======================================#

is( file_is_sticky($tff), 0,
    'file_is_sticky - non-sticky file returns false' );

$mode = oct(1444);
my $chmod_sticky_result = chmod $mode, $tff;
SKIP: {
    skip "Could not set sticky bit on test file", 1 unless ($chmod_sticky_result);
    is( file_is_sticky($tff), 1, 'file_is_sticky - sticky file returns true' );
}

#======================================#
#            file_is_ascii             #
#======================================#

is( file_is_ascii($tf),  1, 'file_is_ascii - ascii file returns true' );
is( file_is_ascii($trf), 0, 'file_is_ascii - non-ascii file returns false' );

#======================================#
#            file_is_binary            #
#======================================#

is( file_is_binary($trf), 1, 'file_is_binary - binary file returns true' );
is( file_is_binary($tff), 0,
    'file_is_binary - non-binary file returns false' );

#======================================#
#            file_is_plain             #
#======================================#

is( file_is_plain($tf),  1, 'file_is_plain - plain file returns true' );
is( file_is_plain($tff), 1, 'file_is_plain - plain file returns true' );
is( file_is_plain($td),  0, 'file_is_plain - non-plain file returns false' );

#======================================#
#        file_is_symbolic_link         #
#======================================#

is( file_is_symbolic_link($tsl),
    1, 'file_is_symbolic_link - symbolic link returns true' );
is( file_is_symbolic_link($td),
    0, 'file_is_symbolic_link - non-link file returns false' );

#======================================#
#             file_is_pipe             #
#======================================#

open( my $tp, '-|', 'echo "Hello World"' ) or croak "Couldn't open pipe.\n";
is( file_is_pipe($tp), 1, 'file_is_pipe - pipe returns true' );
close($tp);
is( file_is_pipe($tf), 0, 'file_is_pipe - non-pipe returns false' );

#======================================#
#            file_is_socket            #
#======================================#

is( file_is_socket($ts), 1, 'file_is_socket - socket returns true' );
is( file_is_socket($tf), 0, 'file_is_socket - non-socket returns false' );

#======================================#
#            file_is_block             #
#======================================#

my $block_file;
if ( is_mac() ) {
    $block_file = '/dev/disk0';
}
elsif ( is_linux() ) {
    $block_file = '/dev/loop0';
}
else {
    $block_file = undef;
}

SKIP: {
    skip "Block file is required for file_is_block test.", 1
        unless ( defined $block_file && file_exists($block_file) );
    is( file_is_block($block_file),
        1, 'file_is_block - block file returns true' );
}

is( file_is_block($tf), 0, 'file_is_block - non-block file returns false' );

#======================================#
#          file_is_character           #
#======================================#

my $character_file = '/dev/zero';

SKIP: {
    skip "Character file is required for file_is_character test.", 1
        unless ( file_exists($character_file) );
    is( file_is_character($character_file),
        1, 'file_is_character - character file returns true' );
}

is( file_is_character($tf), 0,
    'file_is_character - non-character file returns false' );

#======================================#
#              dir_exists              #
#======================================#

is( dir_exists($td),     1, 'dir_exists - exigent dir returns true' );
is( dir_exists($no_dir), 0, 'dir_exists - non-existant dir returns false' );

#======================================#
#             dir_readable             #
#======================================#

$mode = oct(000);
chmod $mode, $td;
SKIP: {
    skip "Root user - test not valid", 1 if ( $REAL_USER_ID == 0 );
    is( dir_readable($td), 0, 'dir_readable - non-readable dir returns false' );
}
$mode = oct(400);
chmod $mode, $td;
is( dir_readable($td), 1, 'dir_readable - readable dir returns true' );

#======================================#
#            dir_writable              #
#======================================#
SKIP: {
    skip "Root user - test not valid", 1 if ( $REAL_USER_ID == 0 );
    is( dir_writable($td), 0, 'dir_writable - non-writable dir returns false' );
}
$mode = oct(200);
chmod $mode, $td;
is( dir_writable($td), 1, 'dir_writable - writable dir returns true' );

#======================================#
#            dir_executable            #
#======================================#
SKIP: {
    skip "Root user - test not valid", 1 if ( $REAL_USER_ID == 0 );
    is( dir_executable($td), 0,
        'dir_executable - non-executable dir returns false' );
}
$mode = oct(100);
chmod $mode, $td;
is( dir_executable($td), 1, 'dir_executable - executable dir returns true' );
$mode = oct(700);
chmod $mode, $td;

#======================================#
#           dir_suffix_slash           #
#======================================#

my $test_dir_w  = '/abc/def/';
my $test_dir_wo = '/abc/def';
is( dir_suffix_slash($test_dir_w),
    $test_dir_w,
    "dir_suffix_slash - don't change dir if has trailing slash" );
is( dir_suffix_slash($test_dir_wo),
    $test_dir_w, "dir_suffix_slash - add slash to dir if no trailing slash" );

#======================================#
#              mk_temp_dir             #
#======================================#

# no additional tests needed as functionality is tested above

#======================================#
#              mk_temp_file            #
#======================================#

# no additional tests needed as functionality is tested above

#======================================#
#              stat_date               #
#======================================#
local $ENV{ TZ } = 'America/New_York';    # avoid timezone problems
system("touch -t  202402201217.23 $tf");
my $expected_date = '20240220';
my $file_date     = stat_date($tf);
is( $file_date, $expected_date, "stat_date - default daily case" );

$expected_date = '2024/02/20';
$file_date     = stat_date( $tf, 1 );
is( $file_date, $expected_date, "stat_date - dir_format daily case" );

$expected_date = '202402';
$file_date     = stat_date( $tf, 0, 'monthly' );
is( $file_date, $expected_date, "stat_date - default monthly case" );

$expected_date = '2024/02';
$file_date     = stat_date( $tf, 1, 'monthly' );
is( $file_date, $expected_date, "stat_date - dir_format monthly case" );

#======================================#
#              status_for              #
#======================================#

my $file_size = status_for($tf)->{ size };
is( $file_size, '0', 'status_for - size of file' );

#======================================#
#              read_list               #
#======================================#
my $expected_scalar = "Owner Persist\nIris Seven\n#Fence\n\n";
my $scalar_list     = read_list($tff);
is( $scalar_list, $expected_scalar, 'read_list - scarlar context' );

# comments (begins with #) and blank lines are skipped
my @expected_array = ( 'Owner Persist', 'Iris Seven' );
my @array_list     = read_list($tff);
is( @array_list, @expected_array, 'read_list - list context' );

done_testing;
