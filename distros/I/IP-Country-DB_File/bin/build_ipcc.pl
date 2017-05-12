#!/usr/bin/perl
use strict;
use warnings;

# PODNAME: build_ipcc.pl
# ABSTRACT: Build database for IP::Country::DB_File

use Getopt::Std;
use IP::Country::DB_File::Builder;

my %opts;
Getopt::Std::getopts('vfbrd:', \%opts) or exit(1);

die("extraneous arguments\n") if @ARGV > 1;

my $dir     = $opts{d};
my $package = 'IP::Country::DB_File::Builder';

eval {
    $package->fetch_files($dir, $opts{v}) if $opts{f};

    if($opts{b}) {
        print("Building database...\n") if $opts{v};

        my $builder = $package->new($ARGV[0]);
        $builder->build($dir);

        if ($opts{v}) {
            print("Total merged IPv4 ranges: ", $builder->num_ranges_v4, "\n");
            print("Total merged IPv6 ranges: ", $builder->num_ranges_v6, "\n");

            # We define usable IPv4 address space as
            # 1.0.0.0 - 223.255.255.255 excluding 127.0.0.0/8
            my $num_addresses_v4 = $builder->num_addresses_v4;
            print("Total IPv4 addresses: $num_addresses_v4\n");
            printf(
                "%.2f%% of usable IPv4 address space\n",
                100 * $num_addresses_v4 / 0xde000000,
            );
        }
    }
};

if($@) {
    print STDERR ($@);
}

if($opts{r}) {
    print("Removing statistics files\n") if $opts{v};
    $package->remove_files($dir);
}

__END__

=pod

=encoding UTF-8

=head1 NAME

build_ipcc.pl - Build database for IP::Country::DB_File

=head1 VERSION

version 3.03

=head1 SYNOPSIS

    build_ipcc.pl [OPTIONS] [DBFILE]

Typical usage to verbosely fetch files, build database, and remove files:

    build_ipcc.pl -vfbr

=head1 DESCRIPTION

Build a database for IP address to country translation with
L<IP::Country::DB_File>. I<DBFILE> specifies the database file and defaults to
F<ipcc.db>.

=head1 OPTIONS

You should provide at least one of the I<-f>, I<-b> or I<-r> options,
otherwise this command does nothing.

=head2 -f

Fetch statistics files via FTP.

=head2 -b

Build database. Requires that the files have been fetched.

=head2 -r

Remove statistics files.

=head2 -d [dir]

Directory for the statistics files. Defaults to the current directory.

=head2 -v

Verbose output.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
