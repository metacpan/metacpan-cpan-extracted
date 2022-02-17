use strict;
use warnings;
use File::Find::Rule;
use Test::More;

my @non_inclusive_words = qw/
    master
    slave
    blacklist
    whitelist
/;

my $cond = '(' . join('|', @non_inclusive_words) . ')';

{
    my @files = File::Find::Rule
        ->extras({ untaint => 1 })
        ->exec(sub {
            my $path = $_[2];
            return if $path =~ m!^\.git/!;
            return 1 if $path =~ m!$cond!i;
        })
        ->in('.');
    ok( scalar(@files) == 0 )
        or note join("\n", sort map { "Path:'$_' has keywords." } @files);
}

{
    my @files = File::Find::Rule
        ->extras({ untaint => 1 })
        ->file
        ->ascii
        ->not_name('09_inclusive.t')
        ->exec(sub {
            return if $_[2] =~ m!^\.git/!;
            open my $fh, '<', $_ or die "Could not open '$_'";
            my $content = do { local $/; <$fh> };
            return 1 if $content =~ m!$cond!i;
        })
        ->in('.');
    ok( scalar(@files) == 0 )
        or note join("\n", sort map { "File:'$_' has keywords." } @files);
}

done_testing;
