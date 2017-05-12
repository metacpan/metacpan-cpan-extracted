#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use charnames qw(:full);
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING}
    or plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';

my @data = (
    {
        test   => '01_expand_babel_fish',
        path   => 'example',
        script => '-I../lib -T 01_expand_babel_fish.pl',
        result => <<"EOT",
foo  bar
foo #{name} bar
foo #{count} bar ((#{count} singular|#{count} plural)) baz
foo 0 bar 0 plural baz
foo 1 bar 1 singular baz
foo 2 bar 2 plural baz
foo 3234567.890 bar 3234567.890 plural baz
foo 4234567.89 bar 4234567.89 plural baz
foo #{count :numf} bar ((#{count :numf} singular|#{count :numf} plural)) baz
foo 0 bar 0 plural baz
foo 1 bar 1 singular baz
foo 2 bar 2 plural baz
foo 3.234.567,890 bar 3.234.567,890 plural baz
foo 4.234.567,89 bar 4.234.567,89 plural baz
foo <strong>1.234,56</strong> bar &lt;text&gt; baz
EOT
    },
);

plan tests => 0 + @data;

for my $data (@data) {
    my $dir = getcwd;
    chdir "$dir/$data->{path}";
    my $result = qx{perl $data->{script} 2>&1};
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir $dir;
    eq_or_diff
        $result,
        $data->{result},
        $data->{test};
}
