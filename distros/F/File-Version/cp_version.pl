#!/usr/bin/perl -w

#  Copyright 2003, Nathaniel J. Graham.  All Rights Reserved.
#  This program is free software.  You may copy or redistribute
#  it under the same terms as Perl itself.

use File::Version;
use Getopt::Std;
getopts('sp:r:');

$opt_p = $opt_p && -d $opt_p ? $opt_p : '.';
$opt_r ||= 1;
$opt_s ||= 0;

unless (@ARGV) { die <<'USAGE' }
cp_version.pl - simple versioning system.
Usage: cp_version.pl [OPTIONS] INPUT FILE(s)
  -p  search path
  -r  recursion depth
  -s  follow symbolic links (bool) 
USAGE

shift(@ARGV) if $ARGV[0] eq 'SPECIAL';
my @files = @ARGV;
@files = grep { -f && -r _ } @ARGV;
for(@files) {
    my $info;
    my %args = ( 
        FILE            => $_,
        SEARCH_PATHS    => [ $opt_p ],
        RECURSION_DEPTH => $opt_r,
        FOLLOW_SYMBOLIC => $opt_s, 
    );
    $info = File::Version->new(%args) or next; 
    if($info->next_version && &copy($info)) {
       print "$info->{WHOLE} copied to $info->{NEXT_VERSION}\n";  
       next;
    }
    print "$info->{WHOLE} copy failed.\n"; 
}

sub copy {
    my $info = shift;
    return unless ( -f $info->{WHOLE} && -r _ );
    if( -e $info->{NEXT_VERSION} ) {
        print "$info->{NEXT_VERSION} already exists, skipping...\n";
        return;
    }
    open(IN, "< $info->{WHOLE}") or die $!;
    open(OUT, "> $info->{NEXT_VERSION}") or die $!;
    my $size = (stat IN)[11] || 16384;
    while ($len = sysread IN, $buf, $size) {
        if(!defined $len) {
            next if $! =~ /^Interrupted/;
            die ("System read error: $!\n");
        }
        $offset = 0;
        while ($len) {
            defined($written = syswrite OUT, $buf, $len, $offset)
                or die "System write error $!\n";
            $len -= $written;
            $offset += $written;
        };
    }
    return 1;
}

