#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Test::More;

if( $ENV{RELEASE_TESTING} ) {
  plan tests => 3;
}
else {
  plan skip_all => "Set \$ENV{RELEASE_TESTING} to run boilerplate check.";
  exit(0);
}


sub not_in_file_ok {
    my ($filename, %regex) = @_;

    my %violated;

    ## no critic (RequireBriefOpen)
    open  my $fh, '<', $filename
        or croak "couldn't open $filename for reading: $!";

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }
    close $fh;

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
    return;
}

sub module_boilerplate_ok {
    my ($module) = @_;
    ## no critic(regular expression)
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
    return;
}

not_in_file_ok(README =>
"The README is used..."       => qr/The README is used/,
"'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
"placeholder date/time"       => qr(Date/time)  ## no critic(regular expression)
);

module_boilerplate_ok('lib/List/BinarySearch.pm');
