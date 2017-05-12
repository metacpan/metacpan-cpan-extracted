package Test::Gzip::BinarySearch;

use strict;
use warnings;
use File::Spec::Functions qw(catfile);

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw(fixture wipe_index);
}

sub fixture {
    my ($filename, $index) = @_;
    $filename .= ".gz" if $filename !~ /\.gz$/;
    $index ||= "$filename.idx";
    
    $filename = catfile('t', 'fixtures', $filename);
    $index = catfile('t', 'fixtures', $index);

    wipe_index($index);
    return ($filename, $index);
}

sub wipe_index {
    my $index = shift;
    unlink($index) or do {
        croak $! unless $! =~ /No such file or directory/;
    }
}

1;

