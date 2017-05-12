#!/usr/bin/perl -w

use strict;
use Test::More tests => 13;
use File::Spec::Functions qw/canonpath catdir/;
use Cwd qw/getcwd/;

BEGIN { use_ok('File::chdir') }

# _catdir has OS-specific path separators so do the same for getcwd
sub _getcwd { canonpath( getcwd ) }

my $cwd = _getcwd;

ok( tied $CWD,      '$CWD is fit to be tied' );

# First, let's try unlocalized $CWD.
{
    $CWD = 't';
    ::is( _getcwd, catdir($cwd,'t'), 'unlocalized $CWD works' );
    ::is( $CWD,   catdir($cwd,'t'), '  $CWD set' );
}

::is( _getcwd, catdir($cwd,'t'), 'unlocalized $CWD unneffected by blocks' );
::is( $CWD,   catdir($cwd,'t'), '  and still set' );


# Ok, reset ourself for the real test.
$CWD = $cwd;

{
    my $old_dir = $CWD;
    local $CWD = "t";
    ::is( $old_dir, $cwd,           '$CWD fetch works' );
    ::is( _getcwd, catdir($cwd,'t'), 'localized $CWD works' );
}

::is( _getcwd, $cwd,                 '  and resets automatically!' );
::is( $CWD,   $cwd,                 '  $CWD reset, too' );


chdir('t');
is( $CWD,   catdir($cwd,'t'),       'chdir() and $CWD work together' );

#--------------------------------------------------------------------------#
# Exceptions
#--------------------------------------------------------------------------#
my $target = "doesnt_exist";
eval { $CWD = $target };
my $err = $@;
ok( $err, 'failure to chdir throws an error' );
like( $err,  "/Failed to change directory to '\Q$target\E'/", 
        '... and the error message is correct');



