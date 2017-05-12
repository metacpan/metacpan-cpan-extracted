#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use ELF::Extract::Sections;

use Log::Log4perl qw( :easy );

Log::Log4perl->easy_init($DEBUG);

my $extractor = ELF::Extract::Sections->new( file => '/lib/libz.so', );
print "5 Largest Sections:\n";
for ( @{ $extractor->sorted_sections( field => 'size', descending => 1 ) }[ 0 .. 5 ] ) {
    print "$_\n";
    print "-\n";
    print substr( $_->contents, 0, 10 );
    print "\n-\n";
}

__END__

=encoding utf8

=head1 Sample Output

    5 Largest Sections:
    [ Section .rodata of size 24768 in /lib/libz.so @ d480 to 13540 ]
    -
    1.2.3
    -
    [ Section deflateInit_ of size 8384 in /lib/libz.so @ 6b90 to 8c50 ]
    -
    H��E1ɉL$
    -
    [ Section inflateBack of size 7880 in /lib/libz.so @ b590 to d458 ]
    -
    L�t$��|$�
             -
    [ Section inflate of size 7712 in /lib/libz.so @ 9600 to b420 ]
    -
    H�\$��d$�
             -
    [ Section .eh_frame of size 5328 in /lib/libz.so @ 13800 to 14cd0 ]
    -
    z
    -
    [ Section deflateParams of size 3120 in /lib/libz.so @ 5a80 to 66b0 ]
    -
    H�\$��l$�
             -
