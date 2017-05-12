use warnings;
use strict;
use Getopt::Whatever;

for my $key ( keys %ARGV ) {
    if ( ref $ARGV{$key} ) {
        print $key, ' -> ', join( ', ', @{ $ARGV{$key} } ), "\n";
    }
    else {
        print $key, ' -> ', $ARGV{$key}, "\n";
    }
}

print "@ARGV\n";
