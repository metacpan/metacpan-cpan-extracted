#!/usr/bin/perl -w

use strict;

use Test::More;

BEGIN {
    if ( $] < 5.006 ) {
        plan skip_all => 'delete(@array) not available before Perl 5.6';
    }
    else {
        plan tests => 15;
    }
}

use File::Spec::Functions qw/canonpath splitdir catdir splitpath catpath/;
use Cwd qw/getcwd/;

BEGIN { use_ok('File::chdir') }

#--------------------------------------------------------------------------#
# Fixtures and utility subs
#--------------------------------------------------------------------------#-

# _catdir has OS-specific path separators so do the same for getcwd
sub _getcwd { canonpath( getcwd ) }

# reassemble
sub _catpath {
    my ($vol, @dirs) = @_;
    return catpath( $vol, catdir(q{}, @dirs), q{} );
}

# get $vol here and use it later
my ($vol,$cwd) = splitpath(canonpath(getcwd),1);

# get directory list the way a user would use it -- without empty leading dir
# as returned by splitdir;
my @cwd = grep { length } splitdir($cwd);

# Utility sub for checking cases
sub _check_cwd {
    # report failures at the calling line
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $label = pop @_;
    my @expect = @_;
    is( _getcwd, _catpath($vol,@expect),       "$label works" );
    ok( eq_array(\@CWD, [@expect]),      '... and value of @CWD is correct' );
    is( $CWD, _catpath($vol,@expect),        '... and value of $CWD is correct' );
}

#--------------------------------------------------------------------------#-
# Tying test
#--------------------------------------------------------------------------#-

ok( tied @CWD,      '@CWD is fit to be tied' );

#--------------------------------------------------------------------------#
# Delete tests - only from the end of the array (like popping)
#--------------------------------------------------------------------------#

SKIP: {
    if ( $] < 5.006 ) {
        skip 'delete(@array) not available before Perl 5.6', 13;
    }

    # Non-local
    eval { delete $CWD[$#CWD] };
    is( $@, '', "Ordinary delete from end of \@CWD lives" );
    _check_cwd( @cwd[0 .. $#cwd-1], 'Ordinary delete from end of @CWD');

    # Reset
    @CWD = @cwd;

    # Localized 
    {
        # localizing tied arrays doesn't work, perl bug. :(
        # this is a work around.
        local $CWD;

        eval { delete $CWD[$#CWD] };
        is( $@, '', "Ordinary delete from end of \@CWD lives" );
        _check_cwd( @cwd[0 .. $#cwd-1], 'Ordinary delete from end of @CWD');

    }
    
    # Exception: DELETE (middle of array)
    {
        local $CWD;
        push @CWD, 't', 'lib';
        eval { delete $CWD[-2] };
        my $err = $@;
        ok( $err, 'Deleting $CWD[-2] throws an error' );
        like( $err,  "/Can't delete except at the end of \@CWD/", 
            '... and the error message is correct');
    }


}

# Check that localizing $CWD/@CWD reverts properly
_check_cwd( @cwd, 'Reset of localized pop' );


