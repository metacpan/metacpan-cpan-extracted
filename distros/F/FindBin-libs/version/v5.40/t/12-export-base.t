#!/usr/bin/perl

package Testophile;

use v5.8;

#no warnings;    # avoid extraneous nastygrams about qw

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
    eval
    {
        symlink qw( /nonexistant/path/to/something ./dead-link )
    }
}

END
{
    eval
    {
        unlink './dead-link';
    }
}

my %testz
= qw
(
    lib         1
    found       1
    missing     0
    dead-link   0
);


sub check_var
{
    my $name    = shift;
    my $dest    = qualify        $name;
    my $ref     = qualify_to_ref $dest;

    eval
    {
        $testz{ $name }
        ? ok   @{ *$ref }, "Non-empty: \@$dest"
        : ok ! @{ *$ref }, "Empty: \@$dest"
        ;

        1
    }
    or fail "Not installed: '$name', $@";
};

# libs & found should be populated.
# missing and dead should be empty.

my $madness = 'FindBin::libs';

use_ok $madness => qw( export );

$madness->import( qw( export=found      base=t                      ) );
$madness->import( qw( export=missing    base=non-existant-directory ) );
$madness->import( qw( export=dead       base=dead-link              ) );

check_var $_  for keys %testz;

done_testing;

exit 0;
