use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use IPC::Shareable;

say "Before: " . IPC::Shareable::ipcs;

my $h = IPC::Shareable->new(
    key => 'blah',
    create => 1,
    destroy => 1
);

$h->{one}{two} = 'hello, world!';
$h->{one}{three}{four} = 1;

print Dumper $h;

IPC::Shareable::_end;
say "After: " . IPC::Shareable::ipcs;
