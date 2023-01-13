package FASTX::Seq;
#ABSTRACT: A class for representing a sequence for FASTX::Reader

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;

$FASTX::Seq::VERSION = $FASTX::Reader::VERSION;
$FASTX::Seq::DEFAULT_QUALITY = 'I';
$FASTX::Seq::DEFAULT_LINE_LEN = 0;
require Exporter;
our @ISA = qw(Exporter);



sub new {
 
    my ($class, $seq, $name, $comment, $qual) = @_;
 
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
 
    return $self;
 
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
    $self->{seq} = reverse($self->{seq});    
    if ($self->{seq} =~ /U/i) {
        $self->{seq} =~ tr/ACGURYSWKMBDHVacguryswkmbdhv/UGCAYRSWMKVHDBugcayrswmkvhdb/;
    } else {                      
        $self->{seq} =~ tr/ACGTRYSWKMBDHVacgtryswkmbdhv/TGCAYRSWMKVHDBtgcayrswmkvhdb/;
    }
    $self->{qual} = reverse($self->{qual}) if (defined reverse($self->{qual}));
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



sub string {
    # Update comment
    my ($self, @args) = @_;
    my $space = length($self->{comment}) > 0 ? " " : "";
    my $name  = $self->{name} // "sequence";
    my $comment = length($self->{comment}) > 0 ? " " . $self->{comment} : "";
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
    my $space = length($self->{comment}) > 0 ? " " : "";
    my $name  = $self->{name} // "sequence";
    my $comment = length($self->{comment}) > 0 ? " " . $self->{comment} : "";
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
    my $comment = length($self->{comment}) > 0 ? " " . $self->{comment} : "";
    
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

version 1.9.0

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

=head1 MAIN METHODS 

=head2 new($seq, $name, $comment, $qual)

Create a new instance of C<FASTX::Seq>.
The sequence is the only required field.

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

=head2 len()

Length of the sequence

    my $len = $fastq->len();

=head1 SEQUENCE MANIPULATION 

=head2 rev()

Reverse (no complement) the sequence in place.

    my $rev = $fastq->rev();

=head2 rc()

Reverse and complement the sequence B<in place> (as it's revesible).
Supports IUPAC degenerate bases.

    my $rc = $fastq->rc();

=head2 slice()

Retrieve a slice of the sequence (from, length), as perl's substr.
The change is not in place, will return a new object.

    my $slice = $fastq->slice(0, 200);

=head1 STRING GENERATION

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

=cut
