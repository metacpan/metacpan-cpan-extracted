#!perl
use v5.10;

use lib qw(lib);
use Cwd;
use File::FindRoot;

my $original = Cwd::getcwd;

say '-' x 30;
say "From .: ", File::FindRoot->dir_contains( '.git' );

say '-' x 30;
chdir 't';
say "From t: ", File::FindRoot->dir_contains( '.git' );

say '-' x 30;
chdir $original;
say "From original: ", File::FindRoot->dir_contains( '.git', { start_at => File::Spec->catfile( Cwd::getcwd, 't' ) } );

# this one finds nothing
say '-' x 30;
say "From original: ", File::FindRoot->dir_contains( '.yahtzee' );
