use strict;
use warnings;

# This test was generated via Dist::Zilla::Plugin::Test::Compile 2.018

use Test::More 0.88;



use Capture::Tiny qw{ capture };

my @module_files = qw(
Hack/Natas.pm
Hack/Natas/15.pm
Hack/Natas/16.pm
Hack/Natas/IncrementalSearch.pm
);

my @scripts = qw(
bin/natas15
bin/natas16
);

# no fake home requested

my @warnings;
for my $lib (@module_files)
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Mblib', '-e', qq{require q[$lib]});
    };
    is($?, 0, "$lib loaded ok");
    warn $stderr if $stderr;
    push @warnings, $stderr if $stderr;
}

use Test::Script 1.05;
foreach my $file ( @scripts ) {
    script_compiles( $file, "$file compiles" );
}


is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};



done_testing;
