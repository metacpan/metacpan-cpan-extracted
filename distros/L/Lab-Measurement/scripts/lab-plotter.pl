#!/usr/bin/perl

use strict;
use Lab::Data::Plotter;
use Getopt::Long;
use Pod::Usage;

my %options=(#  => default
    listplots   => 0,
    dump        => '',
    eps         => '',
    plot        => '',
    fulllabels  => 0,
);

GetOptions(\%options,
    'listplots!',
    'plot=s',
    'dump=s',
    'eps=s',
    'fulllabels!',
    'help|?',
    'man',
);
pod2usage(1) if $options{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $options{man};

my $metafile=shift(@ARGV) or pod2usage(1);
my $plotter=new Lab::Data::Plotter($metafile,\%options);

if ($options{listplots}) {
    print "Available plots in $metafile:\n";
    my %plots=$plotter->available_plots();
    my $num=1;
    for (sort keys %plots) {
        print qq/$num -> $_ ($plots{$_})\n/;
        $num++;
    }
    exit;
}

if ($options{plot} =~ /^\d+$/) {
    my %plots=$plotter->available_plots();
    $options{plot}=(sort keys %plots)[$options{plot}-1];
}

pod2usage(1) unless ($options{plot});

my $gp=$plotter->plot($options{plot});

my $a=<stdin>;

__END__

=encoding utf8

=head1 NAME

plotter.pl - Plot data with GnuPlot

=head1 SYNOPSIS

plotter.pl [OPTIONS] METAFILE

=head1 DESCRIPTION

This is a commandline tool to plot data that has been recorded using
the L<Lab::Measurement|Lab::Measurement> module.

=head1 OPTIONS AND ARGUMENTS

The file C<METAFILE> contains the meta information for the data that is
to be plotted. The name OR number of the plot that you want to draw must
be supplied with the C<--plot> option, unless you use the C<--list_plots>
option, that lists all available plots defined in the C<METAFILE>.

=over 2

=item --help|-?

Print short usage information.

=item --man

Show manpage.

=item --listplots

List available plots defined in C<METAFILE>.

=item --plot=name --plot=number

Show the plot with name C<name> or number C<number>. Numbers are
given by the C<--list_plots> option.

=item --dump=filename

Do not plot now, but dump a gnuplot file C<filename> instead.

=item --eps=filename

Don't plot on screen, but create eps file C<filename>.

=item --fulllabels

Also show axis descriptions in plot.

=back

=head1 SEE ALSO

=over 2

=item gnuplot(1)

=item L<Lab::Measurement>

=item L<Lab::Data::Plotter>

=item L<Lab::Data::Meta>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id$.

Copyright 2004 Daniel Schröer.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
