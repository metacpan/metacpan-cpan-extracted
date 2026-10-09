#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();

# NO FILE HERE DECLARES A LEXICAL $a OR $b. A sort block compares the package
# variables of those names, and one written where a `my $b` is in scope
# compares that instead: it warns on some perls, sorts wrongly on all of them,
# and a sibling distribution failed on five smokers for it. A board was called
# $b in a dozen of these tests until the packaging phase renamed it.
#
# The rule is blunt on purpose. "No sort block can see one" needs a parser to
# check; "there are none" needs a pattern.

my @files;
File::Find::find(sub { push @files, $File::Find::name if -f && /\.(?:pm|t|PL)\z/ }, qw(lib t xt));
push @files, 'bin/brandubh', 'Makefile.PL';

my $declares = qr/\b(?:my|our|state|local)\s*(?:\$[ab]\b|\([^)]*\$[ab]\b[^)]*\))/;

cmp_ok(scalar(@files), '>', 30, scalar(@files) . ' files read');
for my $file (sort @files) {
    next if $file eq 'xt/sort-variables.t';
    open my $fh, '<', $file or die "$file: $!";
    my @found;
    while (my $line = <$fh>) {
        push @found, $. if $line =~ $declares;
    }
    is("@found", '', "$file declares no \$a and no \$b");
}

ok('my $b = 1' =~ $declares, 'the pattern sees a plain declaration');
ok('my ($x, $b) = @_' =~ $declares, 'and one in a list');
ok('sort { $a <=> $b } @list' !~ $declares, 'and leaves a sort block alone');
ok('my $bd = $E->new; my $again = 1' !~ $declares, 'as it does a longer name');

done_testing();
