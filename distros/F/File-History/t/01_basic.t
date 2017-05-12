use strict;
use Test::More tests => 15;
use File::History; 
use Path::Class::File;

my $file  = Path::Class::File->new('t', 'history.txt');
my $file2 = Path::Class::File->new('t', 'history2.txt');
my $dummy = Path::Class::File->new('t', 'dummy.txt');

{
    my @history = (
        'echo hogehoge',
        'ls -al',
        'cd /tmp'
    );

    open my $fh, '>>', $file;
    print $fh "$_\n" for @history;
    close($fh);

    my $h = File::History->new(
        filename => "$file"
    );

    is( $h->find_history, $history[2] );
    is( $h->find_history, $history[1] );
    is( $h->find_history, $history[0] ); 

    for (@history) {
        $h->add_history($_);
    }

    is( $h->find_history, $history[2] );
    is( $h->find_history, $history[1] );
    is( $h->find_history, $history[0] );
}

{
    my @history = (
        'echo hogehoge',
        'ls -al',
        'cd /tmp'
    );

    open my $fh, '>>', $file2;
    print $fh "$_\n" for @history;
    close($fh);

    my $h = File::History->new(
        filename => "$file2"
    );

    $h->find_history;
    $h->add_history("add1");
    $h->add_history("add2");

    is( $h->find_history, 'add2' );
    is( $h->find_history, 'add1' );
    is( $h->find_history, 'ls -al' );

    $h->flush;

    my @lines;
    open my $fh2, '<', $file2;
    while(<$fh2>) {
        chomp;
        push @lines, $_;
    }
    close($fh2);

    @lines = reverse @lines;
    is( $lines[0], 'add2' );
    is( $lines[1], 'add1' );
}

{
    my $h = File::History->new(
        filename => $dummy
    );

    is ( $h->find_history, undef );

    my @history = (
        'echo hogehoge',
        'ls -al',
        'cd /tmp'
    );
    for (@history) {
        $h->add_history($_);
    }

    $h->flush;

    my @lines;
    open my $fh, '<', $dummy;
    while(<$fh>) {
        chomp;
        push @lines, $_;
    }
    close($fh);

    for(0..2) {
        is( $history[$_], $lines[$_] );
    }
}

END {
    unlink($file);
    unlink($dummy);
}

