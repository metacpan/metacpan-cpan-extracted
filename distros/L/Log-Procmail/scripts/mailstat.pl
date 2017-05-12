#!/usr/bin/perl -w
use strict;
use Log::Procmail;
use Getopt::Std;
use POSIX qw( strftime );
use vars qw/ %opt /;
use locale;

%opt = (
    oldsuffix => '.old',
    summary   => sub { },
);

getopts( '?hklmots', \%opt ) or usage();

# -h or -?
usage(1) if $opt{h} or $opt{'?'};

# the filename
my $logfile = shift || '';
my $oldlogfile;

# if the file is the old file
if ( $logfile =~ /$opt{oldsuffix}$/o ) {
    $opt{k} = 1;
    $oldlogfile = $logfile;
}
else { $oldlogfile = $logfile . $opt{oldsuffix} }

# -o      use the old logfile
$logfile = $oldlogfile if $opt{o};

# detect if there is new mail
# -s      silent in case of no mail
if ( $logfile ne '-' and $logfile ne '' ) {
    if ( ! -s $logfile ) {
        if ( !$opt{s} ) {
            if ( -f $logfile ) {
                my $time = !-e $oldlogfile ? "\n" : strftime( " %b %d %H:%M\n",
                    localtime( ( stat($oldlogfile) )[9] ) );
                print 'No mail arrived since', $time;
            }
            else { print "Can't find your LOGFILE=$logfile\n";  }
        }
        exit 1;
    }
}
else {
    if ( $logfile ne '-' and -t ) {
        print STDERR
          "Most people don't type their own logfiles;  but, what do I care?\n";
        $opt{t} = 1;
    }
    $opt{k} = 1;
    $logfile = \*STDIN;
}

# -k      keep logfile intact
if ( !$opt{k} ) {
    rename $logfile, $oldlogfile;
    open F, ">> $logfile" or die "Unable to open $logfile: $!";
    print F '';
    close F;
}
else { $oldlogfile = $logfile }

# -t      terse display format
# -l      long display format
if ( !$opt{t} ) {
    if ( $opt{l} ) {
        print "\n  Total Average  Number Folder\n",
          "  ----- -------  ------ ------\n";
        $opt{summary} = sub {
            printf "  ----- -------  ------\n%7d %7d %7d\n", $_[0],
              $_[0] / $_[1], $_[1];
        };
    }
    else {
        print "\n  Total  Number Folder\n", "  -----  ------ ------\n";
        $opt{summary} = sub {
            printf "  -----  ------\n%7d %7d\n", @_;
        };
    }
}

# the per folder format line
$opt{folder} =
  $opt{l}
  ? sub { printf "%7d %7d %7d %s\n", $_[0], $_[0] / $_[1], $_[1], $_[2] }
  : sub { printf "%7d %7d %s\n", @_ };

# and now, let's forget awk and use Log::Procmail
my $log = Log::Procmail->new($oldlogfile);
$log->errors(1);
my ( $rec, $size, %data, @total );

# fetch data
while ( defined( $rec = $log->next ) ) {

    # if it's an error line
    if ( !ref $rec ) {
        my $folder = $opt{m} ? ' ## diagnostic messages ##' : " ## $rec";
        $folder =~ s/\t/\\t/g;
        $data{$folder}[0] ||= 0;
        $data{$folder}[1]++;
        $size = 0;
        next;
    }

    # We got an abstract. Good.
    my $folder = $rec->folder;

    # This is straight from mailstat (don't ask me)
    $folder =~ s{/msg\.[-0-9A-Za-z_]+$}{/};
    $folder =~ s{/new/[-0-9A-Za-z_][-0-9A-Za-z_.,+:%@]*$}{/};
    $folder =~ s{/new/\d+$}{/.};
    $data{$folder}[0] += $size = $rec->size;
    $data{$folder}[1]++;
}
continue {

    # global statistics
    $total[0] += $size;
    $total[1]++;
}

# print the summary
for my $folder ( sort keys %data) {
    $opt{folder}->( @{ $data{$folder} }, $folder );
}
$opt{summary}->(@total);

# the usage function
sub usage {
    print STDERR "Usage: mailstat [-klmots] [logfile]\n";
    if (shift) {
        print STDERR << 'USAGE';
	-k	keep logfile intact
	-l	long display format
	-m	merge any errors into one line
	-o	use the old logfile
	-t	terse display format
	-s	silent in case of no mail
USAGE
    }
    exit 64;
}

__END__

=head1 NAME

mailstat.pl - shows mail-arrival statistics

=head1 SYNOPSIS

mailstat [-klmots] [logfile]

=head1 DESCRIPTION

B<mailstat.pl> example program using Log::Procmail to mimic mailstat(1)

mailstat parses a procmail-generated $LOGFILE and displays a summary about
the messages delivered to all folders (total size, average size,
nr of messages). The $LOGFILE is truncated to zero length, unless the
I<-k> option is used. Exit code 0 if mail arrived, 1 if no mail arrived.

=head1 OPTIONS

=over 4

=item I<-k>

keep logfile intact

=item I<-l>

long display format

=item I<-m>

merge any errors into one line

=item I<-o>

use the old logfile

=item I<-t>

terse display format

=item I<-s>

silent in case of no mail

=back

=head1 NOTES

Customise to your heart's content, this program is only provided
as a guideline.

=head1 AUTHOR

This program was written by Philippe 'BooK' Bruhat as an example of
use for Log::Procmail. It mimics mailstat(1) as much as possible.

The original mailstat(1) was created by S.R. van den Berg,
The Netherlands.

The original manual page was written by Santiago Vila
<sanvila@debian.org> for the Debian GNU/Linux distribution
(but may be used by others).

=head1 COPYRIGHT

Copyright (c) 2002-2005, Philippe Bruhat. All Rights Reserved.

=head1 LICENSE

This script is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=head1 SEE ALSO

L<perl>, L<Log::Procmail>.

=cut

