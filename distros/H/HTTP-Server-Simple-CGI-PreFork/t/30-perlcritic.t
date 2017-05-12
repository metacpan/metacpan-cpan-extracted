use strict;
use warnings;
use File::Spec;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

use Data::Dumper;
use English qw(-no_match_vars);

if ( not $ENV{TEST_CRITIC} ) {
    my $msg = 'Perl::Critic test.  Set $ENV{TEST_CRITIC} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

my @modules = all_modules();
my $tests = 0;
my @fnames;
foreach my $module (@modules) {
    next if($module =~ /Cache::Memcached/);
    my $fname = 'lib/' . $module . '.pm';
    $fname =~ s/\:\:/\//go;
    $tests++;
    push @fnames, $fname;
}
plan(tests => $tests);


my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile, -verbose => "[%p] %m at line %l, column %c.  (Severity: %s)\n   %e\n");
#all_critic_ok();
foreach my $fname (@fnames) {
    #diag "** $fname";
    critic_ok($fname);
}
