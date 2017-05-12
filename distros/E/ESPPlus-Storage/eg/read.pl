use 5.008;
use strict;
use warnings;
use ESPPlus::Storage::Reader::Tie;
use Fcntl qw(LOCK_EX O_WRONLY);
use Getopt::Long;

our $TempFile;
our $Uncompress = '/usr/bin/uncompress';
our $Repository;
our $OutputDir = '.';

GetOptions( 'temp=s' => \$TempFile,
	    'uncompress=s' => \$Uncompress,
	    'repository=s' => \$Repository,
	    'output=s' => \$OutputDir );
usage() unless $Uncompress and $Repository;

unless ($TempFile) {
    $TempFile = `mktemp /tmp/unco.XXX`;
    chomp $TempFile;
}


# OO approach (which is slightly faster)
{
    my $reader = ESPPlus::Storage->new
	( { filename => $Repository,
	    uncompress_function => \&uncompress } )->reader;
    
#    while ( my $record = $reader->next_record_body ) {
#	# ...
#    }
}

# Tied approach - very convenient, slight overhead
{
    use Symbol 'gensym';
    my $rd = gensym;
    tie *$rd, 'ESPPlus::Storage::Reader::Tie', { filename => $Repository,
						 uncompress_function => \&uncompress }
    or die "Can't tie *RD: $!";
    
    print $$_ while <$rd>;
    close $rd or warn "Couldn't close *RD: $!";
}


#END {
#    if ($TempFile) {
#	unlink $TempFile or die "Couldn't delete $TempFile: $!";
#    }
#}

sub usage {
    die "$^X $0 -r ../lib/1008M.rep
  --temp       Scratch file for uncompressing .Z files
               ( `mktemp /tmp/unco.XXX` )

  --uncompress Path to the uncompress executable
               ( /usr/bin/uncompress )
  --repository Path to the ESP+Storage .REP repository to read
  --output     Directory to extract the records to
";
}

sub vis { map join('', map sprintf("\\%o",ord), split //, $_), @_ }

sub uncompress {
    my $compressed = shift;

    {
        my $out = IO::File->new;
        sysopen $out, $TempFile, O_WRONLY
            or die "Couldn't open $TempFile: $!";
        flock $out, LOCK_EX
            or die "Couldn't get an exclusive lock on $TempFile: $!";
        truncate $out, 0
            or die "Couldn't truncate $TempFile: $!";
        binmode $out
            or die "Could binmode $TempFile: $!";
        print $out $$compressed
            or die "Couldnt write to $TempFile: $!";
        close $out
            or die "Couldn't close $TempFile: $!";

    }

    # add error processing as above
    my $in = IO::Handle->new;
    {
        my $sleep_count = 0;
        my $pid = open $in, "-|", $Uncompress, '-c', $TempFile
            or die "Can't exec $Uncompress: $!";
        unless (defined $pid) {
            warn "Cannot fork: $!";
            die "Bailing out" if $sleep_count++ > 6;
            sleep 10;
            redo;
        }
    }

    local $/;
    binmode $in or die "Couldn't binmode \$in: $!";
    my $uncompressed = <$in>;
    close $in or warn "$Uncompress exited $?";

    return \ $uncompressed;
}

