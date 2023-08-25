package FASTX::Reader;
use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
use PerlIO::encoding;
$Data::Dumper::Sortkeys = 1;
use FASTX::Seq;
use File::Basename;
$FASTX::Reader::VERSION = '1.11.0';
require Exporter;
our @ISA = qw(Exporter);

#ABSTRACT: A simple module to parse FASTA and FASTQ files, supporting compressed files and paired-ends.

use constant GZIP_SIGNATURE => pack('C3', 0x1f, 0x8b, 0x08);


sub new {
    # Instantiate object
    my $class = shift @_;
    my $self = bless {} => $class;
    my $args = {};
    
    # Named parameters: undefined $_[0] will read STDIN!
    if (defined $_[0] and substr($_[0], 0, 1) eq '-') {
      my %data = @_;
        # Try parsing
        for my $i (keys %data) {
            if ($i =~ /^-(file|filename)/i) {
                $args->{filename} = $data{$i};
            } elsif ($i =~ /^-(loadseqs)/i) {
                $args->{loadseqs} = $data{$i};
            } else {
                confess "[FASTX::Reader]: Unknown parameter `$i`\n";
            }
        }
    } else {
      # Legacy instantiation
      ($args) = @_;
    }
      
      
      
    if (defined $args->{loadseqs}) {
      if ($args->{loadseqs} eq 'name' or $args->{loadseqs} eq 'names' ) {
        $args->{loadseqs} = 'name';
      } elsif ($args->{loadseqs} eq 'seq' or $args->{loadseqs} eq 'seqs' or $args->{loadseqs} eq "1") {
        $args->{loadseqs} = 'seq';
      } elsif ($args->{loadseqs} eq 'records') {
        $args->{loadseqs} = 'records';
      } else {
        confess("attribute <loadseqs> should be 'name' or 'seq' to specify the key of the hash.");
      }
    }
    
    $self->{filename} = $args->{filename};
    $self->{loadseqs} = $args->{loadseqs};
    $self->{aux}      = [undef];
    $self->{compressed} = 0;
    $self->{fh}       = undef;


    # Check if a filename was provided and not {{STDIN}}
    # uncoverable branch false

    if ( defined $self->{filename} and -d $self->{filename} ) {
      confess __PACKAGE__, " Directory provide where file was expected\n";
    }

    if (defined $self->{filename} and $self->{filename} ne '{{STDIN}}') {
      open my $initial_fh, '<', $self->{filename} or confess "Unable to read file ", $self->{filename}, "\n";
      read( $initial_fh, my $magic_byte, 4 );
      close $initial_fh;

      # See: __BioX::Seq::Stream__ for GZIP (and other) compressed file reader
      if (substr($magic_byte,0,3) eq GZIP_SIGNATURE) {
         $self->{compressed} = 1;
         our $GZIP_BIN = _which('pigz', 'gzip');
         #close $fh;
         if (! defined $GZIP_BIN) {
           $self->{decompressor} = 'IO::Uncompress::Gunzip';
           require IO::Uncompress::Gunzip;
           my $fh = IO::Uncompress::Gunzip->new($self->{filename}, MultiStream => 1);
           $self->{fh} = $fh;
         } else {
           $self->{decompressor} = $GZIP_BIN;
	         open  my $fh, '-|', "$GZIP_BIN -dc $self->{filename}" or confess "Error opening gzip file ", $self->{filename}, ": $!\n";
           $self->{fh} = $fh;
         }
      } elsif (-B $self->{filename}) {

          # BINARY FILE NOT SUPPORTED?
          #close $fh;
          $self->{fh}      = undef;
          $self->{status}  = 1;
          $self->{message} = 'Binary file not supported';
      } else {

	       #close $fh;
      	 open (my $fh,  '<:encoding(utf8):crlf', $self->{filename}) or confess "Unable to read file ", $self->{filename}, ": ", $!, "\n";
         $self->{fh} = $fh;
      }


    } else {
      # Filename not provided, use STDIN
      $self->{fh} = \*STDIN;
      if ($self->{loadseqs}) {
        confess("Load sequences not supported for STDIN");
      }
    }




    if ($self->{loadseqs}) {
      _load_seqs($self);
    }

    return $self;

}


sub records {
  my $self = shift;
  confess "No records loaded with -loadseqs => records!\n" unless $self->{loadseqs} eq 'records';
  return $self->{seqs};
}


sub getRead {
  my $self   = shift;

  #@<instrument>:<run number>:<flowcell ID>:<lane>:<tile>:<x-pos>:<y-pos>:<UMI> <read>:<is filtered>:<control number>:<index>


  return if (defined $self->{status} and $self->{status} == 0);

  #my $aux = $self->{aux};
  my $sequence_data;
  @{ $self->{aux} } = [undef, 0] if (!(@{ $self->{aux} }));


  if ($self->{aux}->[1]) {
    $self->{return_0}++;
  }

  if (!defined($self->{aux}->[0])) {
      while ($self->{line} = readline($self->{fh})) {

          chomp($self->{line});
          if (substr($self->{line}, 0, 1) eq '>' || substr($self->{line}, 0, 1) eq '@') {
              $self->{aux}->[0] = $self->{line};
              last;
          }
      }
      if (!defined($self->{aux}->[0])) {
          $self->{aux}->[1] = 1;
          $self->{return_1}++;
          return;
      }
  }


  # Comments can have more spaces:
  return unless defined $self->{line};
  my ($name, $comm) = $self->{line}=~/^.(\S+)(?:\s+)(.+)/ ? ($1, $2) :
	                    $self->{line}=~/^.(\S+)/ ? ($1, '') : ('?', '');
  my $seq = '';
  my $c;
  $self->{aux}->[0] = undef;
  while ($self->{line} = readline($self->{fh})) {
     # PARSE SEQx
      chomp($self->{line});
      $c = substr($self->{line}, 0, 1);
      last if ($c eq '>' || $c eq '@' || $c eq '+');
      $seq .= $self->{line};
  }
  $self->{aux}->[0] = $self->{line};
  $self->{aux}->[1] = 1 if (!defined($self->{aux}->[0]));
  $sequence_data->{name} = $name;
  $sequence_data->{comment} = $comm;
  $sequence_data->{seq} = $seq;
  $self->{counter}++;
  # Return FASTA
   if ($c ne '+') {
    $self->{return_fasta1}++;
    return $sequence_data;
  }
  my $qual = '';


  while ($self->{line} = readline($self->{fh})) {
      # PARSE QUALITY
      chomp($self->{line});
      $qual .= $self->{line};
      if (length($qual) >= length($seq)) {
          $self->{aux}->[0] = undef;
          $sequence_data->{name} = $name;
          $sequence_data->{seq} = $seq;
          $sequence_data->{comment} = $comm;
          $sequence_data->{qual} = $qual;
          # return FASTQ
          $self->{return_fastq}++;
          return $sequence_data;
      }
  }
  # PROCH
  close $self->{fh};

  $self->{aux}->[1] = 1;
  $sequence_data->{name}    = $name;
  $sequence_data->{seq}     = $seq;
  $sequence_data->{comment} = $comm;
  $self->{counter}++;
  # return FASTA
  $self->{return_fasta2}++;
  return $sequence_data;

}


sub next {
  my $self   = shift;
  my $scalar_read = $self->getRead();
  return unless defined $scalar_read;
  return FASTX::Seq->new( $scalar_read->{seq}  // '', 
                            $scalar_read->{name}   // undef, 
                            $scalar_read->{comment} // undef, 
                            $scalar_read->{qual} // undef);
  
}


sub getFastqRead {
  my $self   = shift;
  my $seq_object = undef;

  return if (defined $self->{status} and $self->{status} == 0);

  $self->{status} = 1;
  my $header = readline($self->{fh});
  my $seq    = readline($self->{fh});
  my $check  = readline($self->{fh});
  my $qual   = readline($self->{fh});


  # Check 4 lines were found (FASTQ)

  unless (defined $qual) {
    if (defined $header) {
      $self->{message} = "Unknown format: FASTQ truncated at " . $header . "?";
      $self->{status} = 0;
    }
    return;
  }

  # Fast format control: header and separator
  if ( (substr($header, 0, 1) eq '@') and (substr($check, 0, 1) eq '+') ) {
    chomp($header);
    chomp($seq);
    chomp($qual);
    # Also control sequence integrity
    if ($seq=~/^[ACGTNacgtn]+$/ and length($seq) == length($qual) ) {
      my ($name, $comments) = split /\s+/, substr($header, 1);
      $seq_object->{name} = $name;
      $seq_object->{comments} = $comments;
      $seq_object->{seq} = $seq;
      $seq_object->{qual} = $qual;
      $self->{counter}++;

    } else {
      # Return error (corrupted FASTQ)
      $self->{message} = "Unknown format: expecting FASTQ (corrupted?)";
      $self->{status} = 0;

    }
  } else {
    # Return error (not a FASTQ)
    $self->{message} = "Unknown format: expecting FASTQ but @ header not found";

    if (substr($header, 0,1 ) eq '>' ) {
      # HINT: is FASTA?
      $self->{message} .= " (might be FASTA instead)";
    }
    $self->{status} = 0;
  }

  return $seq_object;
}


sub getIlluminaRead {
  my $self   = shift;
  my $seq_object = undef;

  return if (defined $self->{status} and $self->{status} == 0);

  $self->{status} = 1;
  my $header = readline($self->{fh});
  my $seq    = readline($self->{fh});
  my $check  = readline($self->{fh});
  my $qual   = readline($self->{fh});


  # Check 4 lines were found (FASTQ)

  unless (defined $qual) {
    if (defined $header) {
      $self->{message} = "Unknown format: FASTQ truncated at " . $header . "?";
      $self->{status} = 0;
    }
    return;
  }

  # Fast format control: header and separator
  if ( (substr($header, 0, 1) eq '@') and (substr($check, 0, 1) eq '+') ) {
    chomp($header);
    chomp($seq);
    chomp($qual);
    # Also control sequence integrity
    if ($seq=~/^[ACGTNacgtn]+$/ and length($seq) == length($qual) ) {
      my ($name, $comments) = split /\s+/, substr($header, 1);
      #@<instrument>:<run number>:<flowcell ID>:<lane>:<tile>:<x-pos>:<y-pos>:<UMI> <read>:<is filtered>:<control number>:<index>
      my ($instrument, $run, $flowcell, $lane, $tile, $x, $y, $umi) = split /:/, $name;
      my ($read, $filtered, $ctrl, $index1, $index2);

      if (not defined $y) {
        $self->{message} = "Unknown format: not Illumina naming: <instrument>:<run number>:<flowcell ID>:<lane>:<tile>:<x-pos>:<y-pos>";
        $self->{status} = 0;
      }

      $seq_object->{name} = $name;
      $seq_object->{comments} = $comments;
      $seq_object->{seq} = $seq;
      $seq_object->{qual} = $qual;

      $seq_object->{instrument} = $instrument;
      $seq_object->{run} = $run;
      $seq_object->{flowcell} = $flowcell;
      $seq_object->{lane} = $lane;
      $seq_object->{tile} = $tile;
      $seq_object->{x} = $x;
      $seq_object->{y} = $y;
      $seq_object->{umi} = $umi;
      $seq_object->{instrument} = $instrument;
      $seq_object->{run} = $run;
      $seq_object->{flowcell} = $flowcell;

      if (defined $comments) {
          ($read, $filtered, $ctrl, $index1, $index2) = split /[:+]/, $comments;
          if ( defined $ctrl ) {
            $seq_object->{read} = $read;
            $filtered eq 'N' ? $seq_object->{filtered} = 0 : $seq_object->{filtered} = 1;
            $seq_object->{control} = $ctrl;
            if ($read eq '1') {
               $seq_object->{index} = $index1;
               $seq_object->{paired_index} =  $index2;
            } else {
              $seq_object->{paired_index} = $index1;
              $seq_object->{index} =  $index2;
            }
          }
      }
      $self->{counter}++;

    } else {
      # Return error (corrupted FASTQ)
      $self->{message} = "Unknown format: expecting FASTQ (corrupted?)";
      $self->{status} = 0;

    }
  } else {
    # Return error (not a FASTQ)
    $self->{message} = "Unknown format: expecting FASTQ but @ header not found";

    if (substr($header, 0,1 ) eq '>' ) {
      # HINT: is FASTA?
      $self->{message} .= " (might be FASTA instead)";
    }
    $self->{status} = 0;
  }

  return $seq_object;
}

sub getFileFormat {
  my $self   = shift;
  my ($filename) = shift;
  return 0 if (not defined $filename);

  open my $fh, '<', $filename or confess "Unable to read file ", $filename, "\n";
  read( $fh, my $magic_byte, 4 );
  close $fh;

  if (substr($magic_byte,0,3) eq GZIP_SIGNATURE) {
    # GZIPPED FILE
    if (! defined $self->{GZIP_BIN}) {
      require IO::Uncompress::Gunzip;
      $fh = IO::Uncompress::Gunzip->new($filename, MultiStream => 1);
    } else {
	    open  $fh, '-|', "$self->{GZIP_BIN} -dc $filename" or confess "Error opening gzip file ", $filename, ": $!\n";
    }
  } else {
    # NOT COMPRESSED
    open  $fh, '<:encoding(utf8)', "$filename" || confess "Unable to read $filename\n$!\n";
  }
  my $first = readline($fh);
  if (substr($first, 0,1) eq '>') {
    #should be FASTA
    return 'fasta';
  } elsif (substr($first, 0, 1) eq '@') {
    #should be fastq
    readline($fh);
    my $sep = readline($fh);
    if ( substr($sep, 0, 1) eq '+' ) {
      #second check for fastq
      return 'fastq';
    }
  } else {
    #unknown format
    return;
  }
}
sub _load_seqs {
  my ($self) = @_;
  return 0 unless (defined $self->{loadseqs});

  my $seqs = undef;
  while (my $s = $self->getRead() ) {
      my ($name, $seq) = ($s->{name}, $s->{seq});
      if ($self->{loadseqs} eq 'name') {
        $seqs->{$name} = $seq;
      } elsif ($self->{loadseqs} eq 'seq') {
        $seqs->{$seq} = $name;
      } else {
        my $r = FASTX::Seq->new(
          -name => $name,
          -seq => $seq,
          -comment => $s->{comments},
          -qual => $s->{qual},
        );
        push(@{$seqs}, $r);
      }

  }
  $self->{seqs} = $seqs;
}


sub _which {
	return if ($^O eq 'MSWin32');
	my $has_which = eval { require File::Which; File::Which->import(); 1};
	if ($has_which) {
		foreach my $cmd (@_) {
			return which($cmd) if (which($cmd));
		}
	} else {
		foreach my $cmd (@_) {
      my $exit;
      eval {
			  `which $cmd  2> /dev/null`;
        $exit = $?;
      };
			return $cmd if ($exit == 0 and not $@);
		}
	}
	return;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FASTX::Reader - A simple module to parse FASTA and FASTQ files, supporting compressed files and paired-ends.

=head1 VERSION

version 1.11.0

=head1 SYNOPSIS

  use FASTX::Reader;
  my $filepath = '/path/to/assembly.fastq';
  die "Input file not found: $filepath\n" unless (-e "$filepath");
  my $fasta_reader = FASTX::Reader->new({ filename => "$filepath" });

  while (my $seq = $fasta_reader->getRead() ) {
    print $seq->{name}, "\t", $seq->{seq}, "\t", $seq->{qual}, "\n";
  }

=head1 BUILD TEST

Every CPAN release is tested by the L<CPAN testers grid|http://matrix.cpantesters.org/?dist=FASTX-Reader>.

=head1 METHODS

=head2 new()

Initialize a new FASTX::Reader object passing 'filename' argument. Will open a filehandle
stored as $object->{fh}.

  my $seq_from_file = FASTX::Reader->new({ filename => "$file" });

To read from STDIN either pass C<{{STDIN}}> as filename, or don't pass a filename at all:

  my $seq_from_stdin = FASTX::Reader->new();

The parameter C<loadseqs> will preload all sequences in a hash having the sequence
name as key and its sequence as value (or the sequences, if passing 'seq' or 1 as value)

  my $seq_from_file = FASTX::Reader->new(
    -filename => "$file",
    -loadseqs => 'name',  # can be "seqs" or "records"
  });

=head2 records() 

Return the records in a single array (FASTX::Seq)

  my $data = FASTX::Reader->new(
    -filename => 'file.fa',
    -loadseqs => 'records');

  for my $i ($data->records()->@*) {
      print $i->as_fasta() if $i->length() > 100;
  }

=head2 getRead()

Will return the next sequence in the FASTA / FASTQ file using Heng Li's implementation of the readfq() algorithm.
The returned object has these attributes:

=over 4

=item I<name>

header of the sequence (identifier)

=item I<comment>

any string after the first whitespace in the header

=item I<seq>

actual sequence

=item I<qual>

quality if the file is FASTQ

=back

=head2 next() 

Get the next sequence as a blessed object, having the same attributes as 
the regular has provided by C<getRead()>: name, comment, seq, qual.
The class for this object is C<FASTX::Seq>.

=head2 getFastqRead()

If the file is FASTQ, this method returns the same read object as I<getRead()> but with a simpler,
FASTQ-specific, parser.
Attributes of the returned object are I<name>, I<comment>, I<seq>, I<qual> (as for I<getRead()>).
It will alter the C<status> attribute of the reader object if the FASTQ format looks terribly wrong.

  use FASTX::Reader;
  my $filepath = '/path/to/assembly.fastq';
  my $fasta_reader = FASTX::Reader->new({ filename => "$filepath" });

  while (my $seq = $fasta_reader->getFastqRead() ) {
    die "Error parsing $filepath: " . $fasta_reader->{message} if ($fasta_reader->{status} != 1);
    print $seq->{name}, "\t", $seq->{seq}, "\t", $seq->{qual}, "\n";
  }

=head2 getIlluminaRead()

If the file is FASTQ, this method returns the same read object as I<getRead()> but with a simpler parser.
Attributes of the returned object are I<name>, I<comment>, I<seq>, I<qual> (as for I<getRead()>).
In addition to this it will parse the name and comment populating these properties fromt the read name:
C<instrument>, C<run>, C<flowcell>, C<lane>, C<tile>, C<x>, C<y>, C<umi>.

If the comment is also present the following will also populated: C<read> (1 for R1, and 2 for R2),
C<index> (barcode of the current read), C<paired_index> (barcode of the other read)
and C<filtered> (true if the read is to be discarded, false elsewhere).

It will alter the C<status> attribute of the reader object if the FASTQ format looks terribly wrong.

  while (my $seq = $fasta_reader->getIlluminaRead() ) {
    print $seq->{name}, "\t", $seq->{instrument}, ',', $seq->{index1}, "\n";
  }

=head2 getFileFormat(filename)

This subroutine returns 'fasta', 'fastq' or <undef> for a given filepath (this is not a method of the instantiated object)

=head1 ACKNOWLEDGEMENTS

=over 4

=item B<Heng Li's readfq()>

This module is a has been inspired by the I<readfq()> subroutine originally written by Heng Li, that I updated
to retain I<sequence comments>. See: L<readfq repository|https://github.com/telatin/readfq>

=item B<Fabrizio Levorin>

has contributed to the prototyping of this module

=back

=head1 SEE ALSO

=over 4

=item L<BioX::Seq::Stream>

The module I would have used if it was available when I started working on this. The .gz reader implementation comes from this module.

=back

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
