#!/usr/bin/perl

use strict;
use warnings;
use open qw(:std :utf8);
use Text::CSV;
use POSIX();


my %tld_types = (
    # html name             -> enum name
    'generic'               => 'TLD_TYPE_GENERIC',
    'country-code'          => 'TLD_TYPE_COUNTRY_CODE',
    'generic-restricted'    => 'TLD_TYPE_GENERIC_RESTRICTED',
    'infrastructure'        => 'TLD_TYPE_INFRASTRUCTURE',
    'test'                  => 'TLD_TYPE_TEST',
    'sponsored'             => 'TLD_TYPE_SPONSORED',
);


sub gen_test(@) {
    my ($out_file, $csv_file) = @_;


    open (my $out, ">", $out_file)
        or die "open: $out_file: $!";

    my $csv = Text::CSV->new( {
        'binary'    => 1,
        'auto_diag' => 1,
        'eol'       => $/
    } )
        or die "Text::CSV: " . Text::CSV->error_diag();

    open (my $io, "<", $csv_file)
        or die "open: $csv_file: $!";

    # skip header
    $csv->getline($io);

    # generate tld names list
    printf $out "# this file was auto-generated at %s\n",
           POSIX::strftime("%F %T", localtime);

    while ( my $row = $csv->getline($io) ) {
        exists $tld_types{ $row->[1] }
            or die "$csv_file: unknown TLD type: " . $row->[1];

        printf $out "%s.%s\n", $row->[0], $row->[0];
    }

    close ($io)
        or die "close: $csv_file: $!";
    close ($out)
        or die "close: $out_file: $!";
}


if (@ARGV == 2) {
    &gen_test(@ARGV);
    exit 0;
} else {
    print "usage: gen_utf8_pass_test.pl OUT_FILE CSV_FILE\n";
    exit 1;
}
