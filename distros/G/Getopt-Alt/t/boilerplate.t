#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME' => qr/ - The great new /,
        'boilerplate description'   => qr/Quick summary of what the module/,
        'stub function definition'  => qr/function[12]/,
        'module description'        => qr/One-line description of module/,
        'description'               => qr/A full description of the module/,
        'subs / methods'            => qr/section listing the public components/,
        'diagnostics'               => qr/A list of every error and warning message/,
        'config and environment'    => qr/A full explanation of any configuration/,
        'dependencies'              => qr/A list of all of the other modules that this module relies upon/,
        'incompatible'              => qr/any modules that this module cannot be used/,
        'bugs and limitations'      => qr/A list of known problems/,
        'contact details'           => qr/<contact address>/,
    );
}

not_in_file_ok((-f 'README' ? 'README' : 'README.pod') =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

module_boilerplate_ok('lib/Getopt/Alt.pm');
module_boilerplate_ok('lib/Getopt/Alt/Command.pm');
module_boilerplate_ok('lib/Getopt/Alt/CookBook.pod');
module_boilerplate_ok('lib/Getopt/Alt/Dynamic.pm');
module_boilerplate_ok('lib/Getopt/Alt/Exception.pm');
module_boilerplate_ok('lib/Getopt/Alt/Manual.pod');
module_boilerplate_ok('lib/Getopt/Alt/Option.pm');
done_testing();
