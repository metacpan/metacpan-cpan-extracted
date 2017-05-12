#!/usr/bin/perl
package inc::GenerateIndex;

use common::sense;

use Moose;
with 'Dist::Zilla::Role::BeforeBuild';

use Fcntl;
use Text::CSV;

sub before_build {
    my ($self) = @_;
    $self->log('Generating index...');

    my $csv = new Text::CSV;

    sysopen(my $idx, 'share/cep.idx', O_CREAT|O_WRONLY) or die "Error writing: $!";

    open(my $fh, '<:encoding(latin1)', 'share/cep.csv') or die "Error opening CSV: $!";
    my $c   = 0;
    my $pos = 0;
    my $last= 0;
    while (my $row = $csv->getline($fh)) {
        die "Order broken" if ($row->[0] < $last) or ($row->[0] > $row->[1]);
        $last = $row->[1];

        syswrite($idx, pack('N*', $row->[0], $pos));
        syswrite($idx, pack('N*', $row->[1], $pos));

        $pos = tell $fh;
    } continue {
        ++$c;
    }
    $csv->eof or $csv->error_diag;
    close $fh;

    close $idx;

    $self->log("Wrote $c entries.");
}

1;
