#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for author testing";
        exit;
    }
}

use strict;
use warnings;

use IO::File;
use IO::Dir;
use Sort::Versions qw< versioncmp >;

$| = 1;

my $testno = 0;
my $failno = 0;

END {
    print "1..$testno\n";
    exit $failno == 0 ? 0 : 1;
}

# Search for changelog files.

my @files;

my $dh = IO::Dir -> new('.')
  or die "can't open the current directory for reading: $!";

for my $filename ($dh -> read()) {

    # changelog, changelog.txt, changes, changes.log, changes.txt changes.log
    next unless $filename =~ / ^
                               (
                                   changelog ( \. txt )?
                               |
                                   changes ( \. ( log | txt ) )?
                               )
                               $
                             /ix && -f $filename;
    my @info = stat(_);
    my ($dev, $ino, $size) = @info[0, 1, 7];
    push @files, [ $filename, $size ];
}

$dh -> close()
  or die "can't close directory after reading: $!";

# Check number of files found.

unless (@files) {
    print "not ";
    $failno++;
}
print "ok ", ++$testno, " - found changelog file(s)\n";

# Process each changelog file.

for (my $i = 0 ; $i <= $#files ; $i++) {
    my $filename = $files[$i][0];
    my $filesize = $files[$i][1];

    unless ($filesize) {
        print "not ";
        $failno++;
    }
    print "ok ", ++$testno, " - changelog file '$filename' is non-empty\n";

    # Keep each line that starts with a non-whitespace character.

    my @lines = ();

    my $fh = IO::File -> new($filename)
      or die "$filename: can't open file for reading: $!\n";

    while (defined(my $line = <$fh>)) {
        push @lines, [ $line, $. ] if $line =~ /^\S/;
    }

    $fh -> close()
      or die "$filename: can't close file after reading: $!\n";

    # Check the lines, working backwards.

    my $ver_prev;

    for (my $i = $#lines ; $i >= 0 ; $i--) {
        my ($line, $number) = @{ $lines[$i] };

        if ($line =~ /^(\S+) (\S+)( \S+)*$/) {
            my ($ver, $date) = ($1, $2);

            if ($i < $#lines) {
                ++$testno;
                my $ok = versioncmp($ver_prev, $ver) == -1;
                unless ($ok) {
                    print "not ";
                    $failno++;
                }
                print "ok $testno - version numbers '$ver_prev' vs. '$ver'",
                  " are in increasing order\n";
                print STDERR <<"EOF" unless $ok;
#   file '$filename' line $number:
#                version: '$ver'
#       previous version: '$ver_prev'
EOF
            }
            $ver_prev = $ver;

            ++$testno;
            my $ok = $date =~ /^\d{4}-\d{2}-\d{2}$/;
            unless ($ok) {
                print "not ";
                $failno++;
            }
            print "ok $testno - release date '$date' is ISO 8601 extended",
              " format\n";
            print STDERR <<"EOF" unless $ok;
#   file '$filename' line $number:
#               date is: '$date'
#       expected format: 'YYYY-MM-DD'
EOF
        }
    }
}
