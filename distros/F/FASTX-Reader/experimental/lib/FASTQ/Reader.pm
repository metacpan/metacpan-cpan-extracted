package FASTQ::Reader;
use 5.014;

use warnings;

$FASTQ::Reader::VERSION = '0.01';
#ABSTRACT: Internal test code for non-Moose file reader;


use Carp qw(confess);

sub new {
    # INstantiate object
    my ($class, $args) = @_;

    my $self = {
        filename  => $args->{filename},
    };

    # Check file readability
    open my $fh,  '<:encoding(UTF-8)', $self->{filename} or confess "Unable to read file ", $self->{filename}, ": ", $!, "\n";
    my $object = bless $self, $class;

    # Initialize auxiliary array for getRead
    $object->{aux} = [undef];
    $object->{fh} = $fh;
    return $object;
}


sub getRead {
  my $self   = shift;
  #my ($fh, $aux) = @_;
  my $fh = $self->{fh};
  my $aux = $self->{aux};
  my $return;
  @$aux = [undef, 0] if (!(@$aux));	# remove deprecated 'defined'
  return if ($aux->[1]);
  if (!defined($aux->[0])) {
      while (<$fh>) {
          chomp;
          if (substr($_, 0, 1) eq '>' || substr($_, 0, 1) eq '@') {
              $aux->[0] = $_;
              last;
          }
      }
      if (!defined($aux->[0])) {
          $aux->[1] = 1;
          return;
      }
  }
  my $name = /^.(\S+)/? $1 : '';
  my $comm = /^.\S+\s+(.*)/? $1 : ''; # retain "comment"
  my $seq = '';
  my $c;
  $aux->[0] = undef;
  while (<$fh>) {
      chomp;
      $c = substr($_, 0, 1);
      last if ($c eq '>' || $c eq '@' || $c eq '+');
      $seq .= $_;
  }
  $aux->[0] = $_;
  $aux->[1] = 1 if (!defined($aux->[0]));
  $return->{name} = $name;
  $return->{seq} = $seq;
  $self->{counter}++;
  return $return if ($c ne '+');
  my $qual = '';
  while (<$fh>) {
      chomp;
      $qual .= $_;
      if (length($qual) >= length($seq)) {
          $aux->[0] = undef;
          $return->{name} = $name;
          $return->{seq} = $seq;
          $return->{comment} = $comm;
          $return->{qual} = $qual;
          #$self->{counter}+=100;
          return $return;
      }
  }
  $aux->[1] = 1;
  $return->{name} = $name;
  $return->{seq} = $seq;
  $return->{comment} = $comm;
  $self->{counter}++;
  return $return;

}



sub getFastqRead {
  my $self   = shift;
  my $seq_object = undef;
  my $header = readline($self->{fh});
  my $seq    = readline($self->{fh});
  my $check  = readline($self->{fh});
  my $qual   = readline($self->{fh});

  # Check 4 lines were found (FASTQ)
  return undef unless (defined $qual);
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
    $self->{message} = "Unknown format: expecting FASTQ (wrong header)";

    if (substr($seq, 0,1 ) eq '>' ) {
      # HINT: is FASTA?
      $self->{message} .= " (might be FASTA instead)";
    }
    $self->{status} = 0;
  }

  return $seq_object;
}

sub getFileFormat {
  my ($filename) = shift;
  open my $f, '<:encoding(UTF-8)', "$filename" || confess "Unable to read $filename\n$!\n";
  my $first = readline($f);
  if (substr($first, 0,1) eq '>') {
    #should be FASTA
    return 'fasta';
  } elsif (substr($first, 0, 1) eq '@') {
    #should be fastq
    readline($f);
    my $sep = readline($f);
    if ( substr($sep, 0, 1) eq '+' ) {
      #second check for fastq
      return 'fastq';
    }
  } else {
    #unknown format
    return undef;
  }
}


1;
