######################################################################
# Test suite for Git::Meta
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use Cwd;
use Test::More;
use GitMeta::Github;

BEGIN {
    if(exists $ENV{"LIVE_TESTS"}) {
        plan tests => 1;
    } else {
        plan skip_all => "- only with LIVE_TESTS";
    }
}

my $g = GitMeta::Github->new( user => "mschilli" );
my @repos = $g->expand();

ok scalar @repos > 30, "pagination: 30+ repos";
