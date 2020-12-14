package Health::BladderDiary::GenChart;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-11'; # DATE
our $DIST = 'Health-BladderDiary-GenChart'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_bladder_chart_from_entries);

use Data::Clone;
use Hash::Subset qw(hash_subset);
use Health::BladderDiary::GenTable;

our %SPEC;

my $meta = clone $Health::BladderDiary::GenTable::SPEC{gen_bladder_diary_table_from_entries};
$meta->{args}{date}{req} = 1;

$SPEC{gen_bladder_diary_chart_from_entries} = {
    v => 1.1,
    summary => 'Create bladder chart from bladder diary entries',
    args => {
        %{ $meta->{args} },
    },
};
sub gen_bladder_diary_chart_from_entries {
    require Chart::Gnuplot;
    require File::Temp;
    require List::Util;
    #require Math::Round;

    my %args = @_;
    my $date = $args{date};

    my $res = Health::BladderDiary::GenTable::gen_bladder_diary_table_from_entries(
        hash_subset(\%args, $meta->{args}),
    );
    #use DD; dd $res;

    my ($tempfh, $tempfilename) = File::Temp::tempfile();
    $tempfilename .= ".png";

    my (@x_urate, @y_urate);
    my $max_urate_scale;
  SET_RATE_DATASET: {
        my $prev_hour;
        my $max_urate;
        my $datecur = $date->clone;
        for my $entry (@{ $res->[2] }) {
            last if !keys %$entry; # blank line marks the end of entries
            my $rate = $entry->{'urate (ml/h)'};
            next unless defined $rate;
            my $time = $entry->{'urin/defec time'};
            my ($hour, $minute) = $time =~ /(\d+)\.(\d+)/;
            if (defined $prev_hour && $prev_hour > $hour) {
                $datecur->add(days => 1);
            }
            push @x_urate, sprintf("%sT%02d:%02d", $datecur->ymd, $hour, $minute);
            push @y_urate, $rate;
            $max_urate = $rate if !defined $max_urate || $max_urate < $rate;
            $prev_hour = $hour;
        }
        $max_urate_scale = 250;
        $max_urate_scale+= 250 while $max_urate_scale < $max_urate;
    }

    my (@x_ivol, @y_ivol);
    my $max_ivol_scale;
  SET_INTAKE_DATASET: {
        my $prev_hour;
        my $max_ivol;
        my $datecur = $date->clone;
        for my $entry (@{ $res->[2] }) {
            last if !keys %$entry; # blank line marks the end of entries
            my $vol = $entry->{'ivol (ml)'};
            next unless defined $vol;
            my $time = $entry->{'itime'};
            my ($hour, $minute) = $time =~ /(\d+)\.(\d+)/;
            if (defined $prev_hour && $prev_hour > $hour) {
                $datecur->add(days => 1);
            }
            push @x_ivol, sprintf("%sT%02d:%02d", $datecur->ymd, $hour, $minute);
            push @y_ivol, $vol;
            $max_ivol = $vol if !defined $max_ivol || $max_ivol < $vol;
            $prev_hour = $hour;
        }
        $max_ivol_scale = 250;
        $max_ivol_scale+= 250 while $max_ivol_scale < $max_ivol;
    }
    my $chart = Chart::Gnuplot->new(
        output   => $tempfilename,
        title    => 'Urine output on '.($date->ymd),
        xlabel   => 'time',
        ylabel   => 'ml/h',
        y2label  => 'ml',
        timeaxis => 'x',
        xtics    => {labelfmt=>'%H:%M'},

        #yrange   => [0, $max_urate_scale],
        #y2range  => [0, $max_ivol_scale],  # XXX why won't take effect?
        yrange   => [0, List::Util::max($max_urate_scale, $max_ivol_scale)],
        y2range  => [0, List::Util::max($max_urate_scale, $max_ivol_scale)],
    );
    my $dataset_urate = Chart::Gnuplot::DataSet->new(
        xdata => \@x_urate,
        ydata => \@y_urate,
        timefmt => '%Y-%m-%dT%H:%M',
        title => 'Urine output (ml/h)',
        color => 'red',
        style => 'linespoints',
    );
    my $dataset_ivol = Chart::Gnuplot::DataSet->new(
        xdata => \@x_ivol,
        ydata => \@y_ivol,
        timefmt => '%Y-%m-%dT%H:%M',
        title => 'Intake volume (ml)',
        color => 'blue',
        style => 'points',
    );

    $chart->plot2d($dataset_urate, $dataset_ivol);

    require Browser::Open;
    Browser::Open::open_browser("file:$tempfilename");

    [200];
}

1;
# ABSTRACT: Create bladder diary table from entries

__END__

=pod

=encoding UTF-8

=head1 NAME

Health::BladderDiary::GenChart - Create bladder diary table from entries

=head1 VERSION

This document describes version 0.001 of Health::BladderDiary::GenChart (from Perl distribution Health-BladderDiary-GenChart), released on 2020-12-11.

=head1 SYNOPSIS

Your bladder entries e.g. in `bd-entry1.txt` (I usually write in Org document):

 0730 drink: 300ml type=water

 0718 urinate: 250ml

 0758 urinate: 100ml

 0915 drink 300ml

 1230 drink: 600ml, note=thirsty

 1245 urinate: 200ml

From the command-line (I usually run the script from inside Emacs):

 % gen-bladder-diary-table-from-entries < bd-entry1.txt
 | time     | intake type | itime | ivol (ml) | ivol cum | icomment | urination time | uvol (ml) | uvol cum | urgency (0-3) | ucolor (0-3) | ucomment |
 |----------+-------------+-------+-----------+----------+----------+----------------+-----------+----------+---------------+--------------+----------+
 | 07-08.00 | water       | 07.30 |       300 |      300 |          |          07.18 |       250 |      250 |               |              |          |
 |          |             |       |           |          |          |          07.58 |       100 |      350 |               |              |          |
 | 08-09.00 |             |       |           |          |          |                |           |          |               |              |          |
 | 09-10.00 | water       | 09.15 |       300 |      600 |          |                |           |          |               |              |          |
 | 10-11.00 |             |       |           |          |          |                |           |          |               |              |          |
 | 12-13.00 | water       | 12.30 |       600 |     1200 | thirsty  |          12.45 |       200 |          |               |              |          |
 |          |             |       |           |          |          |                |           |          |               |              |          |
 | total    |             |       |      1200 |          |          |                |       550 |          |               |              |          |
 | freq     |             |       |         3 |          |          |                |         3 |          |               |              |          |
 | avg      |             |       |       400 |          |          |                |       183 |          |               |              |          |

Produce CSV instead:

 % gen-bladder-diary-table-from-entries --format csv < bd-entry1.txt > bd-entry1.csv

=head1 DESCRIPTION

This module can be used to visualize bladder diary entries (which is more
comfortable to type in) into table form (which is more comfortable to look at).

=head2 Diary entries

The input to the module is bladder diary entries in the form of text. The
entries should be written in paragraphs, chronologically, each separated by a
blank line. If there is no blank line, then entries are assumed to be written in
single lines.

The format of an entry is:

 <TIME> ("-" <TIME2>)? WS EVENT (":")? WS EXTRA

It is designed to be easy to write. Time can be written as C<hh:mm> or just
C<hhmm> in 24h format.

Event can be one of C<drink> (or C<d> for short), C<eat>, C<urinate> (or C<u> or
C<urin> for short), C<poop>, or C<comment> (or C<c> for short).

Extra is a free-form text, but you can use C<word>=C<text> syntax to write
key-value pairs. Some recognized keys are: C<vol>, C<comment>, C<type>,
C<urgency>, C<color>.

Some other information are scraped for writing convenience:

 /\b(\d+)ml\b/          for volume
 /\bv(\d+)\b/           for volume
 /\bu([0-9]|10)\b/      for urgency (1-10)
 /\bc([0-6])\b/         for clear to dark orange color (0=clear, 1=light yellow, 2=yellow, 3=dark yellow, 4=amber, 5=brown, 6=red)

Example C<drink> entry (all are equivalent):

 07:30 drink: vol=300ml
 0730 drink 300ml
 0730 d 300ml

Example C<urinate> entry (all are equivalent):

 07:45 urinate: vol=200ml urgency=4 color=light yellow comment=at home
 0745 urin 200ml urgency=4 color=light yellow comment=at home
 0745 u 200ml u4 c1 comment=at home

=head3 Urination entries

A urination entry is an entry with event C<urination> (can be written as just
C<u> or C<urin>). At least volume is required, can be written in ml unit e.g.
C<300ml>, or using C<vNUMBER> e.g. C<v300>, or using C<vol> key, e.g.
C<vol=300>. Example:

 1230 u 200ml

You can also enter color, using C<color=NAME> or C<c0>..C<c6> for short. These
colors from 7-color-in-test-tube urine color chart is recommended:
L<https://www.dreamstime.com/urine-color-chart-test-tubes-medical-vector-illustration-image163017644>
or
L<https://stock.adobe.com/images/urine-color-chart-urine-in-test-tubes-medical-vector/299230365>:

 0 - clear
 1 - light yellow
 2 - yellow
 3 - dark yellow
 4 - amber
 5 - brown
 6 - red

Example:

 1230 u 200ml c2

You can also enter urgency information using C<urgency=NUMBER> or C<u0>..C<u10>,
which is a number from 0 (not urgent at all) to 10 (most urgent). Example:

 1230 u 200ml c2 u4

=head2 Drink (fluid intake) entries

A drink (fluid intake) entry is an entry with event C<drink> (can be written as
just C<d>). At least volume is required, can be written in ml unit e.g.
C<300ml>, or using C<vNUMBER> e.g. C<v300>, or using C<vol> key, e.g.
C<vol=300>. Example:

 1300 d 300ml

You can also input the kind of drink using C<type=NAME>. If type is not
specified, C<water> is assumed. Example:

 1300 d 300ml type=coffee

=head2 Eat (food intake) entries

The diary can also contain food intake entries. Currently volume or weight of
food (or volume of fluid, by percentage of food volume) is not measured or
displayed. You can put comments here for more detailed information. The table
generator will create a row for each food intake, but will just display the
time, type ("food"), and comment columns.

=head1 KEYWORDS

voiding diary, bladder diary

=head1 FUNCTIONS


=head2 gen_bladder_diary_chart_from_entries

Usage:

 gen_bladder_diary_chart_from_entries(%args) -> [status, msg, payload, meta]

Create bladder chart from bladder diary entries.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

=item * B<entries>* => I<str>

=item * B<yesterday_last_urination_entry> => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Health-BladderDiary-GenChart>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Health-BladderDiary-GenChart>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Health-BladderDiary-GenChart/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
