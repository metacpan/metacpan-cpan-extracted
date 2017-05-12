#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use ELF::Extract::Sections;

use Log::Log4perl qw( :easy );

my $extractor = ELF::Extract::Sections->new( file => '/lib/libz.so', );
for (qw( .comment .gnu.version .gnu.libstr )) {
    print $extractor->sections->{$_}, "\n";
    print "--\n";
    print $extractor->sections->{$_}->contents;
    print "\n--\n";
}

__END__

=head1 Sample Output

    [ Section .comment of size 1108 in /lib/libz.so @ 151e0 to 15634 ]
    --
    GCC: (Gentoo 4.4.0_alpha20090313) 4.4.0-alpha20090313  (experimental)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090421) 4.4.0-alpha20090421  (prerelease)GCC: (Gentoo 4.4.0_alpha20090313) 4.4.0-alpha20090313  (experimental)
    --
    [ Section .gnu.version of size 182 in /lib/libz.so @ 152a to 15e0 ]
    --

    --
    [ Section .gnu.libstr of size 44 in /lib/libz.so @ 15674 to 156a0 ]
    --
    libc.so.6/lib64/ld-linux-x86-64.so.2
    --

