#!/usr/bin/perl -w
use strict;

use Test::More;
use IO::File;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

my $fh = IO::File->new('Changes','r')   or plan skip_all => "Cannot open Changes file";

plan 'no_plan';

use Mail::File;
my $version = $Mail::File::VERSION;

my $latest = 0;
while(<$fh>) {
    next        unless(m!^\d!);
    $latest = 1 if(m!^$version!);

    # 2012-08-26T01:02 or 2012-08-26T01:02:03 or 2012-08-26T01:02:03.04 or 2012-08-26T01:02+01:00

    like($_, qr!^
                \d[\d._]+\s+                # version
                (   \d{4}-\d{2}-\d{2}       # 2012-08-26    - YYYY-MM-DD
                    (   T\d{2}:\d{2}        # T01:02        - Thh:mm
                        (   :\d{2}          # :02           - :ss
                            (   \.\d+       # .2            - .ss (microseconds)
                            )?
                        )?
                        (   (Z|[-+]\d+:\d+) # +01:00        - timezone
                        )?
                    )?
                ) 
                \s*$!x,'... version has a date');
}

is($latest,1,'... latest version not listed');
