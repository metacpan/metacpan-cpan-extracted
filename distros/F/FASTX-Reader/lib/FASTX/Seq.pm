package FASTX::Seq;
#ABSTRACT: A class for representing a sequence for FASTX::Reader

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;

$FASTX::Seq::VERSION           = $FASTX::Reader::VERSION;
$FASTX::Seq::DEFAULT_QUALITY   = 'I';
$FASTX::Seq::DEFAULT_LINE_LEN  = 0;
$FASTX::Seq::DEFAULT_OFFSET    = 33;
require Exporter;
our @ISA = qw(Exporter);



sub new {
    my $class = shift @_;
    my ($seq, $name, $comment, $qual, $offset, $line_len, $default_quality);
    if (not defined $_[0]) {
        confess "ERROR FASTX::Seq: Sequence missing, record cannot be created.\n";
    }
    # Descriptive instantiation with parameters -param => value
    if (substr($_[0], 0, 1) eq '-') {
        my %data = @_;
        # Try parsing
        for my $i (keys %data) {
            if ($i =~ /^-(seq|sequence)/) {
                $seq = $data{$i};
            } elsif ($i =~ /^-(name|id)/) {
                $name = $data{$i};
            } elsif ($i =~ /^-(comment|desc|description)/) {
                $comment = $data{$i};
            } elsif ($i =~ /^-qual(ity)?/) {
                $qual = $data{$i};
            } elsif ($i =~ /^-offset/) {
                $offset = $data{$i};
            } elsif ($i =~ /^-line_len/) {
                $line_len = $data{$i};
            } elsif ($i =~ /^-default_quality/) {
                $default_quality = $data{$i};
            } else {
                confess "ERROR FASTX::Seq: Unknown parameter $i\n";
            }
        }
    } elsif (not defined $seq) {
        # Positional instantiation
        # check number of arguments
        confess "ERROR FASTX::Seq: Wrong number of arguments\n" if (scalar(@_) < 1 || scalar(@_) > 4);
        ($seq, $name, $comment, $qual) = @_;
    }
 
    # Required NOT empty
    if (not defined $seq) {
        confess "ERROR FASTX::Seq: Sequence missing, record cannot be created\n";
    }

    # If quality is provided, must match sequence length
    if ( defined $seq && defined $qual
      && (length($seq) != length($qual))) {
        confess "Sequence/quality length mismatch";
    }
 
    my $self = bless {}, $class;
    

    $self->{name} = $name   // undef;
    $self->{seq}  = $seq;
    $self->{comment} = $comment // undef;
    $self->{qual} = $qual // undef;
    
    # Store defaults
    $self->{default_quality} = $default_quality // $FASTX::Seq::DEFAULT_QUALITY;
    $self->{line_len} = $line_len // $FASTX::Seq::DEFAULT_LINE_LEN;
    $self->{offset} = $offset // $FASTX::Seq::DEFAULT_OFFSET;
 
    return $self;
 
}


sub copy {
    my ($self) = @_;
    my $copy = __PACKAGE__->new($self->seq, $self->name, $self->comment, $self->qual);
    $copy->{default_quality} = $self->default_quality;
    $copy->line_len = $self->line_len;
    $copy->offset = $self->offset;
    return $copy;
}


sub seq : lvalue {
    # Update sequence
    my ($self, $new_val) = @_;
    $self->{seq} = $new_val if (defined $new_val);
    return $self->{seq};
}



sub name : lvalue {
    # Update name
    my ($self, $new_val) = @_;
    $self->{seq} = $new_val if (defined $new_val);
    return $self->{name};
}



sub qual : lvalue {
    # Update quality
    my ($self, $new_val) = @_;
    $self->{qual} = $new_val if (defined $new_val);
    return $self->{qual};
}


sub comment : lvalue {
    # Update comment
    my ($self, $new_val) = @_;
    $self->{comment} = $new_val if (defined $new_val);
    return $self->{comment};
}


sub offset : lvalue {
    # Update offset
    my ($self, $new_val) = @_;
    confess "ERROR FASTX::Seq: offset must be a positive integer" if (defined $new_val && $new_val !~ /^\d+$/);
    $self->{offset} = $new_val if (defined $new_val);
    return $self->{offset};
}


sub line_len : lvalue {
    # Update line_len
    my ($self, $new_val) = @_;
    confess "ERROR FASTX::Seq: line_len must be a positive integer" if (defined $new_val && $new_val !~ /^\d+$/);
    $self->{line_len} = $new_val if (defined $new_val);
    return $self->{line_len};
}


sub default_quality : lvalue {
    # Update default_quality
    my ($self, $new_val) = @_;
    confess "ERROR FASTX::Seq: default_quality must be a single character" if (defined $new_val && length($new_val) != 1);
    $self->{default_quality} = $new_val if (defined $new_val);
    return $self->{default_quality};
}


sub len {
    # Update comment
    my ($self) = @_;
    return length($self->{seq});
}





sub rev {
    # Update comment
    my ($self) = @_;
    $self->{seq} = reverse($self->{seq});
    $self->{qual} = reverse($self->{qual}) if (defined reverse($self->{qual}));
    return $self;
}



sub rc {
    # Update comment
    my ($self) = @_;
    $self->rev();    
    if ($self->{seq} =~ /U/i) {
        $self->{seq} =~ tr/ACGURYSWKMBDHVacguryswkmbdhv/UGCAYRSWMKVHDBugcayrswmkvhdb/;
    } else {                      
        $self->{seq} =~ tr/ACGTRYSWKMBDHVacgtryswkmbdhv/TGCAYRSWMKVHDBtgcayrswmkvhdb/;
    }
    #$self->{qual} = reverse($self->{qual}) if (defined reverse($self->{qual}));
    return $self;
}


sub slice {
    # Update comment
    my ($self, $from, $len) = @_;
    my $new_seq;
    my $new_qual;
    if (defined($len)) {
      $new_seq = substr($self->{seq}, $from, $len);
      $new_qual = defined($self->{qual}) ? substr($self->{qual}, $from, $len) : undef;
    } else {
        $new_seq = substr($self->{seq}, $from);
        $new_qual = defined($self->{qual}) ? substr($self->{qual}, $from) : undef;
    }
    return __PACKAGE__->new($new_seq, $self->{name}, $self->{comment}, $new_qual);
}


sub char2qual {
    my ($self, $quality_encoded, $offset) = @_;
    # Check quality_encoded is a single character
    confess "Quality encoded character must be a single character" if (length($quality_encoded) != 1);
    $offset = defined $offset ? $offset : $FASTX::Seq::DEFAULT_OFFSET;
    return unpack("C*", $quality_encoded) - $offset;
}


sub qual2char {
    my ($self, $quality_integer, $offset) = @_;
    confess "Quality integer must be an integer value" if ($quality_integer !~ /^\d+$/);
    $offset = defined $offset ? $offset : $FASTX::Seq::DEFAULT_OFFSET;
    return chr($quality_integer + $offset);
}



sub qualities {
    my ($self) = @_;
    my @qualities;
    if (defined $self->{qual}) {
        for (my $i = 0; $i < length($self->{qual}); $i++) {
            push @qualities, $self->char2qual(substr($self->{qual}, $i, 1), $self->{offset});
        }
    }
    return @qualities;
}


sub min_qual {
    my ($self) = @_;
    my @qualities = $self->qualities();
    # Calculate minimum quality
    @qualities = sort {$a <=> $b} @qualities;
    return $qualities[0];
}



sub max_qual {
    my ($self) = @_;
    my @qualities = $self->qualities();
    # Calculate minimum quality
    @qualities = sort {$b <=> $a} @qualities;
    return $qualities[0];
}


sub trim_after  : lvalue {
    my ($self, $qual_value) = @_;
    confess "Quality integer must be an integer value" if ($qual_value !~ /^\d+$/);
    # Detect first base with quality lower or equal than $qual_value
    my $i = 0;
    my @qualities = $self->qualities();
    for ($i = 0; $i < scalar(@qualities); $i++) {
        if ($qualities[$i] <= $qual_value) {
            last;
        }
    }
    # Trim sequence and quality
    my $slice = $self->slice(0, $i);
    $self->{seq} = $slice->{seq};
    $self->{qual} = $slice->{qual};
    return $self;
}



sub trim_until  : lvalue {
    my ($self, $qual_value) = @_;
    confess "Quality integer must be an integer value" if ($qual_value !~ /^\d+$/);
    # Detect first base with quality lower or equal than $qual_value
    my $i = 0;
    my @qualities = $self->qualities();
    for ($i = 0; $i < scalar(@qualities); $i++) {
        if ($qualities[$i] >= $qual_value) {
            last;
        }
    }
    # Trim sequence and quality
    my $slice = $self->slice($i);
    $self->{seq} = $slice->{seq};
    $self->{qual} = $slice->{qual};
    
    return $self;
}

sub _kmer2num {
    my ($kmer) = @_;

    my %baseVal = ('T' => 0, 'C' => 1, 'A' => 2, 'G' => 3, 'U' => 0);
    my $klen = length($kmer);
    my $num = 0;

    for my $i (0..($klen - 1)) {
        if (exists $baseVal{substr($kmer, $i, 1)}) {
            my $p = 4 ** ($klen - 1 - $i);
            $num += $p * $baseVal{substr($kmer, $i, 1)};
        } else {
            $num = -1;
            last;
        }
    }

    return $num;
}


sub translate {
    my ($self, $code_number) = @_;

    my $record = $self->copy();
    # Default genetic code if not specified
    $code_number //= 11;
    
    my @code_map = (
     "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", #1 
     "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG",
     "FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG",
     "FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "", 
     "",
     "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG",
     "FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", #11 Bact, Ar and Plant Plast
     "FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG",
     "FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG",
     "FFLLSSSSYY*QCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", #15 
     "FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "", "", "", "",
     "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG",
     "FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG",
     "FFLLSSSSYY**CCGWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYY**CC*WLLLAPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYYYYCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYYEECC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
     "FFLLSSSSYYEECCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG"
    );
    
    my $code = $code_map[$code_number - 1];
    # Check sequence is nucleotidic or RNA
    confess "ERROR FASTX::Seq: Sequence must be nucleotidic" if ($self->{seq} !~ /^[ACGTU]+$/i);
    my @nucleotides = split //, $self->seq;
    my @translated_sequence;
    
    for (my $i = 0; $i < scalar(@nucleotides) - 2; $i += 3) {
        my $codon = $nucleotides[$i] . $nucleotides[$i+1] . $nucleotides[$i+2];
        my $num = _kmer2num($codon);  # You need to define this function
        if ($num != -1) {
            push @translated_sequence, substr($code, $num, 1);
             
        } else {
            push @translated_sequence, '-';
             
        }
    }
    
    my $translated_seq = join('', @translated_sequence);
    
    $record->seq($translated_seq);
    # Remove qual if present
    $record->qual(undef);
    return $record;
}


sub string {
    # Update comment
    my ($self, @args) = @_;
    if (defined $self->{qual}) {
        return $self->asfastq(@args);
    } else {
        return $self->asfasta(@args);
    }
    
}


sub as_string {
    # Update comment
    my ($self) = @_;
    return $self->string();
}



sub asfasta {
    # Update comment
    my ($self, $len) = @_;
    
    my $name  = $self->{name} // "sequence";
    my $comment = (defined $self->{comment} and length($self->{comment}) > 0) ? " " . $self->{comment} : "";
    return ">" . $name . $comment . "\n" . _split_string($self->{seq}, $len) . "\n";
}


sub asfastq {
    # Update comment
    my ($self, $user_quality) = @_;
    my $quality = $self->{qual};

    if (defined $user_quality) {
        # User requests new quality
        if (length($user_quality) == 1 ) {
            # And it's valid!
            $quality = $user_quality x length($self->{seq});
        } else {
            say STDERR "[WARNING] FASTX::Seq->as_fastq(): Provide a _char_ as quality, not a value (", $user_quality,"): defaulting to $FASTX::Seq::DEFAULT_QUALITY";
            $quality = $FASTX::Seq::DEFAULT_QUALITY x length($self->{seq});
        }
    } elsif (not defined $quality) {
        $quality = $FASTX::Seq::DEFAULT_QUALITY x length($self->{seq});
    }
    
    
    my $name  = $self->{name} // "sequence";
    my $comment = (defined $self->{comment} and length($self->{comment}) > 0) ? " " . $self->{comment} : "";
    
    return "@" . $name . $comment . "\n" . $self->{seq} . "\n+\n" . $quality  . "\n";
}




sub as_fasta {
    # Update comment
    my ($self, @args) = @_;
    return $self->asfasta(@args);
}


sub as_fastq {
    # Update comment
    my ($self, @args) = @_;
    return $self->asfastq(@args);
}


sub is_fasta {
    # Return true if record has no quality
    my ($self) = @_;
    return ((defined $self->{qual}) > 0 and length($self->{qual}) == length($self->{seq})) ? 0 : 1;
}


sub is_fastq {
    # Update comment
    my ($self) = @_;
    return ((defined $self->{qual}) > 0 and length($self->{qual}) == length($self->{seq})) ? 1 : 0;
}


sub _split_string {
	my ($string, $width) = @_;
	if (not defined $width or $width == 0) {
		return "$string";
	}

	my $output_string;
	for (my $i=0; $i<length($string); $i+=$width) {
		my $frag = substr($string, $i, $width);
		$output_string.=$frag."\n";
	}
    chomp($output_string);
	return $output_string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FASTX::Seq - A class for representing a sequence for FASTX::Reader

=head1 VERSION

version 1.12.0

=head1 SYNOPSIS

A sequence object supported from C<FASTX::Reader> structured as
a C<BioX::Seq> record, but keeping the attribute names as the
scalar natively provided by C<FASTX::Reader>. Order of arguments matters:

=over 4

=item B<seq>

The actual sequence, the only mandatory field (string)

=item B<name>

The sequence identifier, can be omitted (string / undef)

=item B<comment>

The sequence comment, can be omitted (string / undef)

=item B<qual>

The sequence quality, if provided its length must match the sequence one (string / undef)

=back

  use FASTX::Seq;
  my $fastq = new($seq, $name, $comment, $qual);
  my $fasta = new($seq, $name, $comment);
  my $barseq = new("ATGC"); 

  # Change attribute
  $fastq->seq("ATGCTT");

=head2 GLOBAL VARIABLES

=head3 C<$FASTX::Seq::DEFAULT_QUALITY> [default: 'I']

Default quality character to use when no quality is provided.
Stored in each record as C<default_quality>.

=head3 C<$FASTX::Seq::DEFAULT_LINE_LEN> [default: 0]

Default line length for FASTA output. If set to 0, no line break is added.
Stored in each record as C<line_len>.

=head3 C<$FASTX::Seq::DEFAULT_OFFSET> [default: 33]

Default quality offset. Default is 33, which is the standard for Sanger/Illumina 1.8+.
Stored in each record as C<offset>.

=head1 NAME

FASTX::Seq - A class for representing a sequence for FASTX::Reader

=head1 VERSION

version 1.11.0

=head1 MAIN METHODS 

=head2 new($seq, $name, $comment, $qual)

Create a new instance of C<FASTX::Seq>.
The sequence is the only required field.

Positional arguments (order matters, only the first is mandatory, 
but comment must be I<undef> if qual is not provided):

  my $record = FASTX::Seq->new($seq, $name, $comment, $qual);

Named arguments (order does not matter, only C<-seq> is mandatory, other can be omitted):

  my $fastq_record = FASTX::Seq->new(
    -seq => "CACCA",                       # -sequence is also valid
    -name => $name,                        # -id is also valid
    -comment => $comment,
    -qual => "IFIGH",                      # -quality is also valid
    -offset => 33,
    -line_len => $line_len,
    -default_quality => $default_quality,
  );

=head2 copy()

Create a copy of the current instance.

    my $copy = $fastq->copy();

=head2 seq()

Get or update the sequence field.

    my $seq = $fastq->seq();
    $fastq->seq("ATGCTT");

=head2 name()

Get or update the sequence field.

    my $seq = $fastq->name();
    $fastq->name("seq1");

=head2 qual()

Get or update the sequence field.

    my $seq = $fastq->qual();
    $fastq->qual("IIIII");

=head2 comment()

Get or update the sequence field.

    my $seq = $fastq->comment();
    $fastq->comment("len=" . length($fastq->seq()));

=head2 offset()

Get or update the sequence field.

    $fastq->offset(33);

=head2 line_len()

Get or update the sequence field.

    $fastq->line_len(33);

=head2 default_quality()

Get or update the sequence field.

    $fastq->default_quality(33);

=head2 len()

Length of the sequence

    my $len = $fastq->len();

=head1 SEQUENCE MANIPULATION 

=head2 rev()

Reverse (no complement) the sequence B<in place>.

    my $rev = $fastq->rev();

=head2 rc()

Reverse and complement the sequence B<in place> (as it's revesible).
Supports IUPAC degenerate bases.

    my $rc = $fastq->rc();

=head2 slice()

Retrieve a slice of the sequence (from, length), as perl's substr.
The change is not in place, will return a new object.

    my $slice = $fastq->slice(0, 200);

=head2 translate([genetic_code])

Return the sequence as translated protein sequence.
Optional artument is the NCBI Genetic code:

    my $seq = FASTX::Seq->new(
        -seq => 'ATGATG',
        -id => 'seq1',
    );
    my $orf = $seq->translate(11);

    say $orf->seq();

=head1 QUALITY

=head2 char2qual(char, [offset]])

Convert encoded quality to its integer value. 
If offset is not provided, will use the default offset.

    my $encoded_phred = $fastq->qual2phred("!", 33);

=head2 qual2char(int, [offset])

Convert integer quality score to encoded phred scores.
If offset is not provided, will use the default offset.

    my $encoded_phred = $fastq->qual2phred("!", 33);

=head2 qualities()

Returns an array of quality values for each base of the record.

    my @qualities = $fastq->qualities();

=head2 min_qual()

Return the lowest quality score in the record.

    my @qualities = $fastq->min_qual();

=head2 max_qual()

Return the lowest quality score in the record.

    my @qualities = $fastq->max_qual();

=head2 trim_after(quality_integer)

Trim the record in place after the first base with a quality score lower or equal than the provided integer.

    $fastq->trim_after(20);

=head2 trim_until(quality_integer)

Trim the record B<in place up to the the first base with a quality score higher or equal than the provided integer>.

    $fastq->trim_until(20);

=head1 VALIDATION AND STRING GENERATION

=head2 string()

Return the sequence as a string. If arguments are provided, they
will be treated as FASTA or FASTQ specific according to the record format.

    print $seq->string();

=head2 as_string()

Alias to string()

=head2 asfasta([length]])

Return the sequence as a FASTA string. If the I<length> is provided, the
sequence will be split into lines of that length.

    my $fasta = $seq->asfasta();

=head2 asfastq()

Return the sequence as a FASTQ string. Will use a dummy fixed value quality
if the sequence didnt have a quality string. 
Provide an character to use it as quality value, B<will override> the record quality,
if it has one.

    my $fasta = $seq->asfastq();

=head2 as_fasta()

Alias to asfasta()

=head2 as_fastq()

Alias to asfastq()

=head2 is_fasta()

Return true if the record has not a quality value stored (FASTA)

    if ( $seq->is_fasta() ) {
        ...
    }

=head2 is_fastq()

Return true if the record has a quality value stored (FASTQ)

    if ( $seq->is_fastq() ) {
        ...
    }

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
