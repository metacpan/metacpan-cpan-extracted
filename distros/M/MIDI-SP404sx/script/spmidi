#!perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use MIDI::SP404sx::PTNIO;
use MIDI::SP404sx::MIDIIO;
use Log::Log4perl qw(:easy);

# process command line arguments
my ( $infile, $outfile, $verbosity, $length );
GetOptions(
    'infile=s'  => \$infile,
    'outfile=s' => \$outfile,
    'verbose+'  => \$verbosity,
    'length=i'  => \$length, # length in bars, e.g. 4/4 = *1* bar, only for reading MIDI
);

# configure logger
if ( $verbosity ) {
    my $log_level = ( 3 - $verbosity ) * 10000;
    Log::Log4perl->easy_init($log_level);
}

# will be input and output classes
my ( $reader, $writer );

# determine the input
if ( $infile =~ /\.mid$/i ) {
    $reader = 'MIDI::SP404sx::MIDIIO';
}
elsif ( $infile =~ /\.BIN/i ) {
    $reader = 'MIDI::SP404sx::PTNIO';
}
else {
    die "No reader for file $infile";
}

# determine the output
if ( $outfile =~ /\.BIN$/i ) {
    $writer = 'MIDI::SP404sx::PTNIO';
}
elsif ( $outfile =~ /\.mid$/i ) {
    $writer = 'MIDI::SP404sx::MIDIIO';
}
else {
    die "No writer for file $outfile";
}

# do the conversion
my $pattern = $reader->read_pattern($infile);
if ( $length ) {
    $pattern->nlength($length);
}
$writer->write_pattern($pattern, $outfile);
