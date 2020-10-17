#!/usr/bin/perl

use strict;
use warnings;
use open qw(:std :utf8);
use POSIX ();
use Text::CSV;


my %tld_types = (
    # html name             -> enum name
    'generic'               => 'TLD_TYPE_GENERIC',
    'country-code'          => 'TLD_TYPE_COUNTRY_CODE',
    'generic-restricted'    => 'TLD_TYPE_GENERIC_RESTRICTED',
    'infrastructure'        => 'TLD_TYPE_INFRASTRUCTURE',
    'test'                  => 'TLD_TYPE_TEST',
    'sponsored'             => 'TLD_TYPE_SPONSORED',
);


sub gen_tld_h($) {
    my ($file) = @_;


    open (my $fh, ">", $file)
        or die "open: $file: $!";

    my $header = <<'EOL';
#ifndef TLD_H
#define TLD_H


typedef struct tld_s {
    const char  *domain;
    size_t      length;
    int         type;
} tld_t;

EOL
    printf $fh $header;

    print $fh "enum {\n";
    print $fh "    TLD_TYPE_UNUSED, /* tests only */\n";
    print $fh "    TLD_TYPE_NOT_ASSIGNED,\n";
    for my $type (sort values %tld_types) {
        print $fh "    ", $type, ",\n";
    }
    print $fh "    TLD_TYPE_SPECIAL,\n";
    print $fh "    TLD_TYPE_RETIRED,\n";
    print $fh "    TLD_TYPE_MAX /* tests only */\n";
    print $fh "};\n\n";

    print $fh "extern const tld_t tld_list[];\n\n";
    print $fh "#endif /* TLD_H */\n\n";

    close ($fh)
        or die "open: $file: $!";
}


sub gen_tld_c(@) {
    my ($h_file, $c_file, $csv_file) = @_;


    open (my $cfh, ">", $c_file)
        or die "open: $c_file: $!";

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
    printf $cfh "/* this file was auto-generated at %s */\n\n",
                POSIX::strftime("%F %T", localtime);
    print $cfh "#include <stdio.h> /* NULL */\n";
    print $cfh "#include \"$h_file\"\n\n";

    print $cfh "const tld_t tld_list[] = {\n";
    my $type = "";
    while ( my $row = $csv->getline($io) ) {
        exists $tld_types{ $row->[1] }
            or die "$csv_file: unknown TLD type: " . $row->[1];
        my $tld_manager = $row->[2];
        if ($tld_manager =~ m/^Not assigned/i) {
            $type = "TLD_TYPE_NOT_ASSIGNED";
        } elsif ($tld_manager =~ m/^Retired/i) {
            $type = "TLD_TYPE_RETIRED";
        } else {
            $type = $tld_types{ $row->[1] };
        }

        printf $cfh "    { \"%s\", %d, %s },\n",
                    $row->[0],
                    length ($row->[0]) + 1,
                    $type;
    }
    printf $cfh "    { NULL, 0, 0 }\n";
    print $cfh "}; /* const tld_t tld_list[] */\n\n";

    close ($io)
        or die "close: $csv_file: $!";
    close ($cfh)
        or die "close: $c_file: $!";
}


if (@ARGV == 3) {
    &gen_tld_h($ARGV[0]);
    &gen_tld_c(@ARGV);
    exit 0;
} else {
    print "usage: gentld.pl H_SOURCE C_SOURCE CSV_FILE\n";
    exit 1;
}
