package Health::BladderDiary::GenTable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-13'; # DATE
our $DIST = 'Health-BladderDiary-GenTable'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_bladder_diary_table_from_entries);

our %SPEC;

$SPEC{gen_bladder_diary_table_from_entries} = {
    v => 1.1,
    summary => 'Create bladder diary table from bladder diary entries',
    args => {
        entries => {
            schema => 'str*',
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_file',
        },
    },
};
sub gen_bladder_diary_table_from_entries {
    my %args = @_;

    my @unparsed_entries;
  SPLIT_ENTRIES: {
        if ($args{entries} =~ /\S\R\R+\S/) {
            # there is a blank line between non-blanks, assume entries are
            # written in paragraphs
            @unparsed_entries = split /\R\R+/, $args{entries};
            for (@unparsed_entries) {
                s/\R+/ /g;
                s/\s+\z//;
            }
        } else {
            # there are no blank lines, assume entries are written as individual
            # lines
            @unparsed_entries = split /^/, $args{entries};
        }
        for (@unparsed_entries) {
            s/\R+/ /g;
            s/\s+\z//;
        }
    } # SPLIT_ENTRIES

    my @urinations;
    my @intakes;
  PARSE_ENTRIES: {
        my $i = 0;
        for my $uentry (@unparsed_entries) {
            my $uentry0 = $uentry;
            $i++;
            my $time;
            $uentry =~ s/\A(\d\d)[:.]?(\d\d)(?:-(\d\d)[:.]?(\d\d))?\s*//
                or return [400, "Entry #$i: invalid time, please start with hhmm or hh:mm: $uentry0"];
            my ($h, $m, $h2, $m2) = ($1, $2, $3, $4);
            $uentry =~ s/(\w+):?\s*//
                or return [400, "Entry #$i: event (e.g. drink, urinate) expected: $uentry"];
            my $event = $1;
            if    ($event eq 'u' || $event eq 'urin') { $event = 'urinate' }
            elsif ($event eq 'd') { $event = 'drink' }
            elsif ($event eq 'c') { $event = 'comment' }
            $event =~ /\A(drink|eat|poop|urinate|comment)\z/
                or return [400, "Entry #$i: unknown event '$event', please choose eat|drink|poop|urinate|comment"];

            my $parsed_entry = {
                # XXX check that time is monotonically increasing
                time => sprintf("%02d.%02d", $h, $m),
                _h    => $h,
                _m    => $m,
                _time => $h*60 + $m,
                _raw  => $uentry0,
            };

            # scrape key-value pairs from unparsed entry
            my %kv;
            while ($uentry =~ /(\w+)=(.+?)(?=[,.]?\s+\w+=|[.]?\s*\z)/g) {
                $kv{$1} = $2;
            }
            #use DD; dd \%kv;

            for my $k (qw/vol type comment urgency color/) {
                if (defined $kv{$k}) {
                    $parsed_entry->{$k} = $kv{$k};
                }
            }

            $uentry =~ /\b(\d+)ml\b/     and $parsed_entry->{vol}     //= $1;
            $uentry =~ /\bv(\d+)\b/      and $parsed_entry->{vol}     //= $1;
            $uentry =~ /\bu([0-9]|10)\b/ and $parsed_entry->{urgency} //= $1;
            $uentry =~ /\bc([0-6])\b/    and $parsed_entry->{color}   //= do {
                if    ($1 == 0) { 'clear' } # very good
                elsif ($1 == 1) { 'light yellow' } # good
                elsif ($1 == 2) { 'yellow' } # fair
                elsif ($1 == 3) { 'dark yellow' } # light dehydrated
                elsif ($1 == 4) { 'amber' } # dehydrated
                elsif ($1 == 5) { 'brown' } # very dehydrated
                elsif ($1 == 6) { 'red' } # severe dehydrated
            };

            if ($event eq 'drink') {
                return [400, "Entry #$i: please specify volume for $event"]
                    unless defined $parsed_entry->{vol};
                $parsed_entry->{type} //= "water";
                push @intakes, $parsed_entry;
            } elsif ($event eq 'eat') {
                $parsed_entry->{type} = "food";
                push @intakes, $parsed_entry;
            } elsif ($event eq 'urinate') {
                return [400, "Entry #$i: please specify volume for $event"]
                unless defined $parsed_entry->{vol};
                $parsed_entry->{"ucomment"} = "poop" . ($parsed_entry->{comment} ? ": $parsed_entry->{comment}" : "");
                push @urinations, $parsed_entry;
            }
        }
    } # PARSE_ENTRIES

    if ($args{_raw}) {
        return [200, "OK", {
            intakes => \@intakes,
            urinations => \@urinations,
        }];
    }

    my @rows;
    my $ivol_cum = 0;
    my $uvol_cum = 0;
    my $prev_utime;
    my $num_drink = 0;
    my $num_urinate = 0;
  GROUP_INTO_HOURS: {
        my $h = do {
            my $hi = @intakes    ? $intakes[0]{_h}    : undef;
            my $hu = @urinations ? $urinations[0]{_h} : undef;
            my $h = $hi // $hu;
            $h = $hi if defined $hi && $hi < $h;
            $h = $hu if defined $hu && $hu < $h;
            $h;
        };
        while (1) {
            last unless @intakes || @urinations;

            my @hour_rows;
            push @hour_rows, {time => sprintf("%02d.00-%02d.00", $h, $h+1 <= 23 ? $h+1 : 0)};

            my $j = 0;
            while (@intakes && $intakes[0]{_h} == $h) {
                my $entry = shift @intakes;
                $hour_rows[$j]{"intake type"} = $entry->{type};
                $hour_rows[$j]{itime}         = $entry->{time};
                $hour_rows[$j]{"icomment"}    = $entry->{comment};
                if (defined $entry->{vol}) {
                    $num_drink++;
                    $hour_rows[$j]{"ivol (ml)"}   = $entry->{vol};
                    $ivol_cum += $entry->{vol};
                    $hour_rows[$j]{"ivol cum"}    = $ivol_cum;
                }
                $j++;
            }

            $j = 0;
            while (@urinations && $urinations[0]{_h} == $h) {
                my $entry = shift @urinations;
                $hour_rows[$j]{"urin/defec time"}  = $entry->{time};
                $hour_rows[$j]{"color"}            = $entry->{color};
                $hour_rows[$j]{"ucomment"}         = $entry->{comment};
                $hour_rows[$j]{"urgency (0-10)"}   = $entry->{urgency};
                if (defined $entry->{vol}) {
                    $num_urinate++;
                    $hour_rows[$j]{"uvol (ml)"}    = $entry->{vol};
                    $uvol_cum += $entry->{vol};
                    $hour_rows[$j]{"uvol cum"}     = $uvol_cum;
                    my $mins_diff;
                    if (defined $prev_utime) {
                        $mins_diff = $prev_utime > $entry->{_time} ? (24*60+$entry->{_time} - $prev_utime) : ($entry->{_time} - $prev_utime);
                    }
                    #$hour_rows[$j]{"utimediff"}    = $mins_diff;
                    $hour_rows[$j]{"urate (ml/h)"} = defined($prev_utime) ?
                        sprintf("%.0f", $entry->{vol} / $mins_diff * 60) : undef;
                }
                $j++;

                $prev_utime = $entry->{_time};
            }
            push @rows, @hour_rows;
            $h++;
            $h = 0 if $h >= 24;
        }
    } # GROUP_INTO_HOURS

  ADD_SUMMARY_ROWS: {
        push @rows, {};

        push @rows, {
            time => 'freq drink/urin',
            'itime' => $num_drink,
            'urin/defec time' => $num_urinate,
        };
        push @rows, {
            time => 'avg (ml)',
            'ivol (ml)' => sprintf("%.0f", $num_drink   ? $ivol_cum / $num_drink   : 0),
            'uvol (ml)' => sprintf("%.0f", $num_urinate ? $uvol_cum / $num_urinate : 0),
        };
    }

    # return result

    [200, "OK", \@rows, {
        'table.fields' => [
            'time',
            'intake type',
            'itime',
            'ivol (ml)',
            'ivol cum',
            'icomment',
            'urin/defec time',
            'uvol (ml)',
            'uvol cum',
            'urate (ml/h)',
            'color',
            'urgency (0-10)',
            'ucomment',
        ],
        'table.field_aligns' => [
            'left', #'time',
            'left', #'intake type',
            'left', #'itime',
            'right', #'ivol (ml)',
            'right', #'ivol cum',
            'left', #'icomment',
            'left', #'urin/defec time',
            'right', #'uvol (ml)',
            'right', #'uvol cum',
            'right', #'urate (ml/h)',
            'left', #'color',
            'left', #'urgency (0-10)',
            'left', #'ucomment',
        ],
    }];
}

1;
# ABSTRACT: Create bladder diary table from entries

__END__

=pod

=encoding UTF-8

=head1 NAME

Health::BladderDiary::GenTable - Create bladder diary table from entries

=head1 VERSION

This document describes version 0.004 of Health::BladderDiary::GenTable (from Perl distribution Health-BladderDiary-GenTable), released on 2020-11-13.

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

=head2 Drink entries

A drink (fluid intake) entry is an entry with event C<drink> (can be written as
just C<d>). At least volume is required, can be written in ml unit e.g.
C<300ml>, or using C<vNUMBER> e.g. C<v300>, or using C<vol> key, e.g.
C<vol=300>. Example:

 1300 d 300ml

You can also input the kind of drink using C<type=NAME>. If type is not
specified, C<water> is assumed. Example:

 1300 d 300ml type=coffee

=head1 KEYWORDS

voiding diary, bladder diary

=head1 FUNCTIONS


=head2 gen_bladder_diary_table_from_entries

Usage:

 gen_bladder_diary_table_from_entries(%args) -> [status, msg, payload, meta]

Create bladder diary table from bladder diary entries.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<entries>* => I<str>


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

Please visit the project's homepage at L<https://metacpan.org/release/Health-BladderDiary-GenTable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Health-BladderDiary-GenTable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Health-BladderDiary-GenTable>

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
