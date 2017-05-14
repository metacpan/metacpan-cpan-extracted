# 002_memory_usage.t

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use feature ':5.10';
use File::Sip;
use File::Slurp 'read_file';
use Memory::Usage;


my $FILE = $ARGV[0] || '/var/log/syslog';
my $mu = Memory::Usage->new();
$mu->record('init');

sub file_slurp {
    my $line_nr = shift;
    my @lines   = read_file($FILE);
    return $lines[$line_nr];
}

sub file_sip {
    my $line_nr = shift;
    my $sip = File::Sip->new( path => $FILE );
    return $sip->read_line($line_nr);
}

file_sip(10);
$mu->record('sip');
my $sip_diff = $mu->state->[1]->[6] - $mu->state->[0]->[6];

file_slurp(10);
$mu->record('slurp');
my $slurp_diff = $mu->state->[2]->[6] - $mu->state->[1]->[6];

my $ratio = $slurp_diff / $sip_diff;
say "$slurp_diff / $sip_diff -> $ratio";
