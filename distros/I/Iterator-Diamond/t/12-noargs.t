#! perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use Iterator::Diamond;

my @payload = (
    "This comes from the pipe\n",
    "Another line from the pipe\n",
);

my $pipe = undef;
my $pid  = eval { open $pipe, '-|' };
if (!defined $pid) {
    plan skip_all => 'fork/pipe not supported here';
}
elsif ($pid) {
    plan tests => 1 + @payload;
}
else {
    open STDIN, '<', File::Spec->devnull;
    print @payload;
    exit;
}

@ARGV = ();
open STDIN, '<&', $pipe or die "cannot redirect STDIN: $!\n";

my $it = Iterator::Diamond->new( magic => "stdin" );

my @lines = ();
while ( <$it> ) {
    push(@lines, $_);
}

is(0+@lines, 0+@payload, 'number of lines');
for my $i ( 0..$#payload ) {
    my $j = $i + 1;
    is($lines[$i], $payload[$i], "line $j");
}
