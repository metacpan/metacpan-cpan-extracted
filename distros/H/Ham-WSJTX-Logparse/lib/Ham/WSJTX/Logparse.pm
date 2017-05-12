package Ham::WSJTX::Logparse;

use 5.006;
use strict;
use warnings;

=head1 NAME

Ham::WSJTX::Logparse - Parses ALL.TXT log files from Joe Taylor K1JT's WSJT-X, to extract CQ and calling station
information for all entries in a given amateur band.

=head1 ACKNOWLEDGEMENTS

Much inspiration was gained from povaX's ALLmon at
https://github.com/poxaV/ALLmon/blob/master/ALLmon
Thank you, povaX!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Extract all log entries for a given band:

    use Ham::WSJTX::Logparse;

    my $log = Ham::WSJTX::Logparse->new();
    # Looks in the default location for the ALL.TXT file
    # or...
    my $log = Ham::WSJTX::Logparse->new("/path/to/an/ALL.TXT");
    # or, can parse multiple logs...
    my $log = Ham::WSJTX::Logparse->new("/tmp/ALL.TXT.one", "/tmp/ALL.TXT.two"); # etc., etc....
    ...

    # Define a callback

    my $callback = sub {
       my $date = shift;
       my $time = shift;
       my $power = shift;
       my $offset = shift;
       my $mode = shift;
       my $callsign = shift;
       my $grid = shift;
       print "date $date time $time power $power offset $offset mode $mode callsign $callsign grid $grid\n";
       # sure you can do something interesting with this!
    };

    $log->parseForBand("20m", $callback);
    # many entries are printed....

=head1 EXPORT

No functions exported; this has a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new(optional list of files)

Constructs a new parser, given an optional list of files. If no files are given, the default locations will be checked
for a WSJT-X ALL.TXT file. Returns a blessed hash.

Note that this module has only been tested on OSX, and the location of default files on non-OSX/Windows platforms is not
known to the author at this time; if you know, please inform me as new will die if it tries to load a default file on
a platform I haven't coded for.

=head2 files($self)

Returns the list of files that the parser was configured with, or the default file as discovered if no files were
supplied in the constructor.

=head2 parseForBand($self, $bandOfInterest, $callback)

Parses all discovered or supplied files, correctly determining the date of each 'heard station' entry, and if the entry
relates to the band of interest, calls the callback with the entry details.

The 'band of interest' is of the form nnnm, e.g. 20m, 2m, 160m, 2200m. Only one band can be filtered at any time.

The callback is a sub as shown above in the synopsis.

Take care with the 'grid' data in your callback: This is extracted from the logged content of a message, and must be
two characers followed by two digits - but if the message was 'M0CUV SV2XYZ RR73', then the grid would be decoded as
'RR73', which is not a valid grid square (of course, this is 'RR 73', but has been concatenated by the SV2 station).
Similarly with TU73. In my callback, I use:

    if ($grid =~ /(TU|RR)73/) {
        warn "dodgy data from $date $time $callsign\n";
        return;
    }

Better validation may be considered for a later release.

An entry is considered a 'heard station' entry if it has some text (maybe CQ or a callsign), followed by some text
(most likely a callsign), followed by a grid square (two characters, two digits - see the note of caution in the
previous paragragh).

=head1 AUTHOR

Matt Gumbley, C<< devzendo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ham-wsjtx-logparse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ham-WSJTX-Logparse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ham::WSJTX::Logparse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ham-WSJTX-Logparse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ham-WSJTX-Logparse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ham-WSJTX-Logparse>

=item * Search CPAN

L<http://search.cpan.org/dist/Ham-WSJTX-Logparse/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Matt Gumbley.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut

our $VERSION = '0.01';

our %freqToBand = (
    '144.491'  => '2m',    # +2
    '144.489'  => '2m',
    '70.093'   => '4m',    # +2
    '70.091'   => '4m',
    '50.278'   => '6m',    # +2
    '50.276'   => '6m',
    '28.078'   => '10m',   # +2
    '28.076'   => '10m',
    '24.919'   => '12m',   # +2
    '24.917'   => '12m',
    '21.078'   => '15m',   # +2
    '21.076'   => '15m',
    '18.104'   => '17m',   # +2
    '18.102'   => '17m',
    '14.078'   => '20m',   # +2
    '14.076'   => '20m',
    '10.14'    => '30m',   # +2
    '10.138'   => '30m',
    '7.078'   => '40m',   # +2
    '7.076'   => '40m',
    '5.359'   => '60m',   # +2
    '5.357'   => '60m',
    '3.578'   => '80m',   # +2
    '3.576'   => '80m',
    '1.84'    => '160m',  # +2
    '1.838'   => '160m',
    '0.4762'  => '630m',  # +2
    '0.4742'  => '630m',
    '0.13813' => '2200m', # +2
    '0.13613' => '2200m',
);

sub new {
    my $class = shift;
    my @files = @_;

    my @filesToUse = scalar(@files) == 0 ? (defaultAllTxtFile()) : @files;
    my $obj = {
        files => [ @filesToUse ],
    };

    foreach my $file (@{$obj->{files}}) {
        die "File '" . $file . "' not found" unless (-f $file);
    }
    bless $obj, $class;
    return $obj;
}

sub defaultAllTxtFile {
    if ($^O eq 'darwin') {
        # povaX' ALLmon suggests >= v1.4 uses standard OSX location:
        my $homeAll = "$ENV{HOME}/Library/Application Support/WSJT-X/ALL.TXT";
        my $globalAll = "/Applications/WSJT-X/ALL.TXT"; # povaX' ALLmon suggests it was here in WSJT-X <= v1.3
        return $homeAll if (-f $homeAll);
        return $globalAll if (-f $globalAll);
        die "Could not find default ALL.TXT";
    } elsif ($^O =~ /^MSWin/ or $^O eq 'cygwin') {
        die "I don't have a Windows system to find the default location of ALL.TXT";
    } else {
        # It has to be some sane kind of UNIX-like, right?
        die "I haven't tried this on non-OSX UNIX-likes";
    }
}

sub files {
    my $self = shift;
    return (@{$self->{files}});
}

sub parseForBand {
    my ($self, $bandOfInterest, $callback) = @_;
    foreach my $file ($self->files()) {
        local *F;
        unless (open F, "<$file") {
            die "Cannot open $file: $!\n";
        }
        my $currentBand = undef;
        my $currentDate = undef;
        while (<F>) {
            chomp;
            #print "line [$_]\n";
            # Only interested in data from a specific band, and the indicator for changing band/mode looks like:
            # 2015-Apr-15 20:13  14.076 MHz  JT9
            # So extract the frequency, and look up the band. This also gives us the date. Records like this are always
            # written at startup, mode change, and at midnight.
            if (/^(\d{4}-\S{3}-\d{2}) \d{2}:\d{2}\s+(\d+\.\d+) MHz\s+\S+\s*$/) {
                $currentDate = $1;
                my $frequency = $2;
                $currentBand = $freqToBand{$frequency};
                #print "data being received for $currentBand (filtering on $bandOfInterest)\n";
                next;
            }
            # Time/Power/Freq offset/Mode/Call/Square can be extracted from records like these:
            # 0000  -9  1.5 1259 # CQ TI4DJ EK70
            # 0001  -1  0.5  404 # DX K1RI FN41
            # 0001  -8  0.2  560 # KC0EFQ WA3ETR FN10
            # 0001 -15  0.1  628 # KK7X K8MDA EN80
            # 0002 -13  1.1 1322 # CQ YV5FRD FK60
            # 0003  -3  0.5 1002 # TF2MSN K1RI FN41
            if (/^(\d{4})\s+(-\d+)\s+[-\d.]+\s+(\d+)\s([#@])\s\w+\s+(\w+)\s+([A-Z]{2}\d{2})\s*$/) {
                my $ctime = $1;
                my $cpower = $2;
                my $coffset = $3;
                my $cmode = $4;
                my $ccallsign = $5;
                my $cgrid = $6;
                # callsigns must have at least one digit.
                next unless ($ccallsign =~ /\d/);
                if (defined $currentDate && $bandOfInterest eq $currentBand) {
                    $callback->($currentDate, $ctime, $cpower, $coffset, $cmode, $ccallsign, $cgrid);
                }
                next;
            }
        }
        close F;
    }
}

1; # End of Ham::WSJTX::Logparse
