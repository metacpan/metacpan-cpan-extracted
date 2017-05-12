#!/usr/bin/perl

package Testophile;

use v5.8;

no warnings;    # avoid extraneous nastygrams about qw

use Symbol;
use Test::More;

$\ = "\n";
$, = "\n\t";

# export @lib after looking for */lib
# export @found after looking for */blib
# export @binz after looking for */bin, override the 
# "ignore" to search /bin, /usr/bin.
#
# eval necessary for crippled O/S w/ missing/broken symlinks.

BEGIN
{
    eval { symlink qw( /nonexistant/path/to/foobar ./foobar ) }
}

END
{
    unlink './foobar';
}

use FindBin::libs qw( export                            );
use FindBin::libs qw( export=found base=blib            );
use FindBin::libs qw( export=junk  base=frobnicatorium  );
use FindBin::libs qw( export       base=foobar          );

my %testz
= qw
(
    lib     1
    found   1
    junk    0
    foobar  0
);

plan tests => 1 * keys %testz;

while( my ($name, $true) = each %testz )
{
    my $dest    = qualify        $name;
    my $ref     = qualify_to_ref $dest;

    $true 
    ? ok   @{ *$ref }, "Non-empty: $dest"
    : ok ! @{ *$ref }, "Empty: $dest"
    ;
}

exit 0;
