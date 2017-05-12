#! perl

use strict;
use warnings;

sub MIDI::Opus::dump_to_file {
    my ($op, $file) = @_;
    open(my $f, ">", $file) or die("$file: $!");
    select $f;
    $op->dump({dump_tracks => 1, flat => 0});
    select STDOUT;
    close($f);
}

sub string_to_file {
    my ($string, $file) = @_;
    open(my $f, ">", $file) or die("$file: $!");
    print { $f } $string;
    close($f);
}

sub slurp {
    my ($file) = @_;
    open(my $f, "<", $file) or die("$file: $!");
    local $/;
    scalar <$f>;
}

sub differ {
    # Returns 1 if the files differ, 0 if the contents are equal.
    my ($old, $new, $text) = @_;
    unless ( open (F1, $old) ) {
	print STDERR ("$old: $!\n");
	return 1;
    }
    unless ( open (F2, $new) ) {
	print STDERR ("$new: $!\n");
	return 1;
    }
    if ( $text ) {
	while ( 1 ) {
	    my $line1 = <F1>;
	    my $line2 = <F2>;
	    return 1 if ($line1 xor $line2);
	    return 0 if !($line1 or $line2);
	    chomp($line1);
	    chomp($line2);
	    return 1 unless $line1 eq $line2;
	}
    }

    binmode(F1);
    binmode(F2);
    my ($buf1, $buf2);
    my ($len1, $len2);
    while ( 1 ) {
	$len1 = sysread (F1, $buf1, 10240);
	$len2 = sysread (F2, $buf2, 10240);
	return 0 if $len1 == $len2 && $len1 == 0;
	return 1 if $len1 != $len2 || ( $len1 && $buf1 ne $buf2 );
    }
}

1;
