use 5.012;
use BioX::Seq::Stream;

# A demo script using the excellent BioX::Seq::Stream module

my $filename = shift @ARGV;
die "$filename not found\n" if (defined $filename and not -e "$filename");
say STDERR "WARNING: Reading from STDIN (Ctrl-C to exit)!\n" unless (defined $filename);

my $parser = BioX::Seq::Stream->new( $filename );

while (my $seq = $parser->next_seq) {
    print $seq->{id}, "\n";
    print $seq->{seq}, "\n";
    print $seq->{qual}, "\n";

    # $seq is a BioX::Seq object

}
