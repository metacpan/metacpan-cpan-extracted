use strict;
use warnings;

# This test was generated via Dist::Zilla::Plugin::Test::Compile 2.018

use Test::More 0.88;



use Capture::Tiny qw{ capture };

my @module_files = qw(
Games/Nintendo/Mario.pm
Games/Nintendo/Mario/Hearts.pm
Games/Nintendo/Mario/NSMB.pm
Games/Nintendo/Mario/NSMB/Wii.pm
Games/Nintendo/Mario/SMB.pm
Games/Nintendo/Mario/SMB2.pm
Games/Nintendo/Mario/SMB3.pm
Games/Nintendo/Mario/SMBTLL.pm
);

my @scripts = qw(

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



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};



done_testing;
