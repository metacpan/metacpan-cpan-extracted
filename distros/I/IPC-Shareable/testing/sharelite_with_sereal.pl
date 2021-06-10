use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use Sereal qw(encode_sereal decode_sereal);
use IPC::ShareLite;

my %shm_opts = (
    -key        => 'test',
    -create     => 1,
    -destroy    => 1,
    -exclusive  => 0,
    -mode       => 0666,
#    -flags      => $flags,
    -size       => 999
);

my $s = IPC::ShareLite->new(%shm_opts);

my %hash = (a => 1, b => 2);

$s->store(encode_sereal(\%hash));
my $d = decode_sereal($s->fetch);

print Dumper $d;

print Dumper $s;

say $s->shmid;
