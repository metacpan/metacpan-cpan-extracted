#!/usr/bin/perl -w

use strict;
use Test::More tests => 55;
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
# Assignment tests
#--------------------------------------------------------------------------#

# Non-local
@CWD = (@cwd, 't');
_check_cwd( @cwd, 't', 'Ordinary assignment');

# Reset
@CWD = @cwd;

# Localized 
{
    # localizing tied arrays doesn't work, perl bug. :(
    # this is a work around.
    local $CWD;

    @CWD = (@cwd, 't');
    _check_cwd( @cwd, 't', 'Localized assignment' );
}

# Check that localizing $CWD/@CWD reverts properly
_check_cwd( @cwd, 'Reset of localized assignment' );

#--------------------------------------------------------------------------#
# Push tests
#--------------------------------------------------------------------------#

# Non-local
push @CWD, 't';
_check_cwd( @cwd, 't', 'Ordinary push');

# Reset
@CWD = @cwd;

# Localized 
{
    # localizing tied arrays doesn't work, perl bug. :(
    # this is a work around.
    local $CWD;

    push @CWD, 't';
    _check_cwd( @cwd, 't', 'Localized push' );
}

# Check that localizing $CWD/@CWD reverts properly
_check_cwd( @cwd, 'Reset of localized push' );

#--------------------------------------------------------------------------#
# Pop tests
#--------------------------------------------------------------------------#

# Non-local
my $popped_dir = pop @CWD;
_check_cwd( @cwd[0 .. $#cwd-1], 'Ordinary pop');
is( $popped_dir, $cwd[-1],          '... and pop returned popped dir' ); 

# Reset
@CWD = @cwd;

# Localized 
{
    # localizing tied arrays doesn't work, perl bug. :(
    # this is a work around.
    local $CWD;

    my $popped_dir = pop @CWD;
    _check_cwd( @cwd[0 .. $#cwd-1], 'Localized pop');
}

# Check that localizing $CWD/@CWD reverts properly
_check_cwd( @cwd, 'Reset of localized pop' );


#--------------------------------------------------------------------------#
# Splice tests
#--------------------------------------------------------------------------#

# Non-local
my @spliced_dirs;

# splice multiple dirs from end
push @CWD, 't', 'lib';
@spliced_dirs = splice @CWD, -2;
_check_cwd( @cwd, 'Ordinary splice (from end)');
is( @spliced_dirs, 2, '... and returns right number of dirs' );
ok( eq_array(\@spliced_dirs, [qw/t lib/]), "... and they're correct" );

# splice a single dir from the middle
push @CWD, 't', 'lib';
@spliced_dirs = splice @CWD, -2, 1;
_check_cwd( @cwd, 'lib', 'Ordinary splice (from middle)');
is( @spliced_dirs, 1, '... and returns right number of dirs' );
ok( eq_array(\@spliced_dirs, ['t']), "... and it's correct" );

# Reset
@CWD = @cwd;

# Localized 
{
    # localizing tied arrays doesn't work, perl bug. :(
    # this is a work around.
    local $CWD;

    # splice multiple dirs from end
    push @CWD, 't', 'lib';
    @spliced_dirs = splice @CWD, -2;
    _check_cwd( @cwd, 'Localized splice (from end)');
    is( @spliced_dirs, 2, '... and returns right number of dirs' );
    ok( eq_array(\@spliced_dirs, [qw/t lib/]), "... and they're correct" );

    # splice a single dir from the middle
    push @CWD, 't', 'lib';
    @spliced_dirs = splice @CWD, -2, 1;
    _check_cwd( @cwd, 'lib', 'Localized splice (from middle)');
    is( @spliced_dirs, 1, '... and returns right number of dirs' );
    ok( eq_array(\@spliced_dirs, ['t']), "... and it's correct" );
}

# Check that localizing $CWD/@CWD reverts properly
_check_cwd( @cwd, 'Reset of localized splice' );

#--------------------------------------------------------------------------#
# Exceptions
#--------------------------------------------------------------------------#


# Change to invalid directory
my $target = "doesnt_exist";
eval { $CWD[@CWD] = $target };
my $err = $@;
ok( $err, 'Failure to chdir throws an error' );
#_check_cwd( @cwd, 'Still in original directory' );

my $missing_dir = quotemeta(File::Spec->catfile($CWD,$target));
like( $err,  "/Failed to change directory to '$missing_dir'/", 
        '... and the error message is correct');

