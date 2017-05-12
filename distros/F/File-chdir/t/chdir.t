#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;
use File::Spec::Functions qw/canonpath catdir/;
use Cwd qw/getcwd/;

BEGIN { use_ok('File::chdir') }

# _catdir has OS-specific path separators so do the same for getcwd
sub _getcwd { canonpath( getcwd ) }

my($cwd) = _getcwd =~ /(.*)/;  # detaint otherwise nothing's gonna work

# First, let's try normal chdir()
{
    chdir('t');
    ::is( _getcwd, catdir($cwd,'t'), 'void chdir still works' );

    chdir($cwd);    # reset

    if( chdir('t') ) {
        1;
    }
    else {
        ::fail('chdir() failed completely in boolean context!');
    }
    ::is( _getcwd, catdir($cwd,'t'),  '  even in boolean context' );
}

::is( _getcwd, catdir($cwd,'t'), '  unneffected by blocks' );


# Ok, reset ourself for the real test.
chdir($cwd) or die $!;

{
    local $ENV{HOME} = 't';
    chdir;
    ::is( _getcwd, catdir($cwd, 't'), 'chdir() with no args' );
    ::is( $CWD, catdir($cwd, 't'), '  $CWD follows' );
}

# Final chdir() back to the original or we confuse the debugger.
chdir($cwd);
